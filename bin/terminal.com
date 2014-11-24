#!/usr/bin/env ruby

# TODO: Not every endpoint requires authentication.

require File.expand_path('../../lib/terminal.com', __FILE__)

def usage
  <<-EOF
== Usage ==

1. Explicit configuration.

#{$0} [user_token] [access_token] [command]

2. With a configuration file.

~/.terminal.com.json
{"user_token": "...", "access_token": "..."}

#{$0} [command]

== Commands ==

These are identical to what the API provides.

- get_snapshot [snapshot_id]
- get_profile [username]
- list_terminals
  EOF
end

# -h | --help
if ARGV.include?('-h') || ARGV.include?('--help')
  puts usage; exit
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

  puts Terminal::API.send(command, user_token, access_token, *ARGV)
end
