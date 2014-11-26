#!/usr/bin/env ruby

# TODO (later): Don't force tokens for methods that don't need them.
# TODO (maybe): DBG=ruby/curl/off. Curl would output curl commands.

############
# Helpers. #
############

def log(message)
  STDERR.puts("\x1B[1;30m~ #{message}\x1B[0m") unless ENV['DBG'] == 'off'
end

def dbg(command, arguments, **options)
  log "Terminal::API.#{command}(" +
    ("#{arguments.inspect[1..-2]}" unless arguments.empty?).to_s +
    (", #{options.inspect[1..-2]}" unless options.empty?).to_s +
    ")\n"
end

def try_highlight_syntax(json)
  CodeRay.scan(json, :json).term
rescue
  json
end

def print_as_json(data)
  json = JSON.pretty_generate(data)
  puts try_highlight_syntax(json)
end

def api_call(command, arguments, options)
  # Ruby **args expansion doesn't work as I expected, that's why the extra if.
  # pry(main)> def xxx(*args) args; end
  # pry(main)> xxx(**{})
  # => [{}]
  if options
    dbg command, arguments, options
    print_as_json Terminal::API.send(command, *arguments, **options)
  else
    dbg command, arguments
    print_as_json Terminal::API.send(command, *arguments)
  end
end

def usage
  if File.exist?(File.expand_path('../docs/help.txt', __dir__))
    # Running locally.
    puts File.read(File.expand_path('../docs/help.txt', __dir__))
  else
    # RubyGems installation.
    spec = Gem::Specification.find_by_name('terminal.com')
    puts File.read(File.join(spec.gem_dir, 'docs', 'help.txt'))
  end
end

#########
# Main. #
#########

require File.expand_path('../../lib/terminal.com', __FILE__)
require 'json'

begin
  require 'coderay'
rescue LoadError
  log "CodeRay is not installed. Syntax highlighting won't be available."
end

# -h | --help
if ARGV.include?('-h') || ARGV.include?('--help')
  puts usage; exit
end

if ARGV.first == 'configure'
  puts <<-EOF
Welcome to the Terminal.com CLI client.

We don't want to bother you with asking for credentials every single time,
so instead we'll ask you for them now and save them to ~/.terminal.com.json.

Alright?

Go to https://www.terminal.com/settings/api

And:
  EOF

  print "1. Paste your user token here: "
  user_token = STDIN.readline.chomp
  print "2. Generate an access token if you don't have one and paste it here: "
  access_token = STDIN.readline.chomp

  File.open(File.expand_path('~/.terminal.com.json'), 'w') do |file|
    file.puts({user_token: user_token, access_token: access_token}.to_json)
  end

  puts "\nYour tokens were saved to ~/.terminal.com.json."
  exit
end

# Tokens.
# TODO: Add --no-config
if File.exist?(File.expand_path('~/.terminal.com.json'))
  config = JSON.parse(File.read(File.expand_path('~/.terminal.com.json')))
  user_token, access_token = config.values_at('user_token', 'access_token')

  if user_token.nil?
    abort("Config file found, but user_token is missing. Add user_token key.")
  end

  if access_token.nil?
    abort("Config file found, but access_token is missing. Add access_token key.")
  end
else
  user_token, access_token = ARGV.shift(2)

  if user_token.nil? || access_token.nil?
    STDERR.puts("Credentials missing.\n\n")
    abort usage
  end
end

if ARGV.empty?
  STDERR.puts("Command missing.\n\n")
  abort usage
else
  command = ARGV.shift

  unless Terminal::API.respond_to?(command)
    STDERR.puts("Invalid command '#{command}'.\n\n")
    abort usage
  end

  # Not every method requires authentication.
  method_args = Terminal::API.method(command).parameters.map(&:last)

  if method_args.include?(:options)
    options = ARGV.reduce(Hash.new) do |buffer, argument|
      if argument.match(/^--(.+)=(.+)$/)
        buffer[$1.to_sym] = $2
      elsif argument.match(/^--no-(.+)$/)
        buffer[$1.to_sym] = false
      elsif argument.match(/^--(.+)$/)
        buffer[$1.to_sym] = true
      end

      buffer
    end

    ARGV.delete_if { |argument| argument.start_with?('--') }
  end

  arguments = []
  arguments << user_token if method_args.include?(:user_token)
  arguments << access_token if method_args.include?(:access_token)
  arguments.push(*ARGV)

  api_call(command, arguments, options)
end
