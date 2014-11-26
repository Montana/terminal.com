#!/usr/bin/env ruby

require File.expand_path('../../lib/terminal.com', __FILE__)

# TODO: Don't force tokens for methods that don't need them.
# TODO: terminal.com configure -> ask for the credentials and save them.
# TODO: Support booleans --featured --no-featured.

def usage
  DATA.read
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

  # Not every method requires authentication.
  method_args = Terminal::API.method(command).parameters.map(&:last)

  if method_args.include?(:options)
    options = ARGV.reduce(Hash.new) do |buffer, argument|
      if argument.match(/^--(.+)=(.+)$/)
        ARGV.delete(argument)
        buffer[$1.to_sym] = $2
      end

      buffer
    end
  end

  arguments = []
  arguments << user_token if method_args.include?(:user_token)
  arguments << access_token if method_args.include?(:access_token)
  arguments.push(*ARGV)

  # Ruby **args expansion doesn't work as I expected, that's why the extra if.
  # pry(main)> def xxx(*args) args; end
  # pry(main)> xxx(**{})
  # => [{}]
  if options
    STDERR.puts("~ Terminal::API.#{command}(*#{arguments.inspect}, **#{options.inspect})\n\n")
    puts Terminal::API.send(command, *arguments, **options)
  else
    STDERR.puts("~ Terminal::API.#{command}(*#{arguments.inspect})\n\n")
    puts Terminal::API.send(command, *arguments)
  end
end

__END__
== Usage ==

1. Explicit configuration.

terminal.com [user_token] [access_token] [command]

2. With a configuration file.

~/.terminal.com.json
{"user_token": "...", "access_token": "..."}

terminal.com [command]

== Commands ==

These are identical to what the API provides.

# BROWSE SNAPSHOTS & USERS #
get_snapshot snapshot_id
get_profile username
list_public_snapshots [options]
  --username=value
  --tag=value
  --featured
  --title=value
  --page=value
  --perPage=value
  --sortby=value

count_public_snapshots [options]
  --username=value
  --tag=value
  --featured
  --title=value

# CREATE AND MANAGE TERMINALS #
list_terminals user_token access_token
get_terminal user_token access_token [options]
  --container_key=value
  --subdomain=value

start_snapshot user_token access_token snapshot_id [options]
  --cpu=value
  --ram=value
  --temporary=value
  --name=value
  --autopause=value
  --startup_script=value
  --custom_data=value

delete_terminal user_token access_token container_key
restart_terminal user_token access_token container_key
pause_terminal user_token access_token container_key
resume_terminal user_token access_token container_key
edit_terminal user_token access_token container_key [options]
  --cpu=value
  --ram=value
  --diskspace=value
  --name=value

# CREATE AND MANAGE SNAPSHOTS #
list_snapshots user_token access_token [options]
  --username=value
  --tag=value
  --featured
  --title=value
  --page=value
  --perPage=value

count_snapshots user_token access_token [options]
  --username=value
  --tag=value
  --featured
  --title=value

delete_snapshot user_token access_token snapshot_id
edit_snapshot user_token access_token snapshot_id [options]
  --body=value
  --title=value
  --readme=value
  --public
  --custom_data=value

snapshot_terminal user_token access_token container_key [options]
  --body=value
  --title=value
  --readme=value
  --public

# MANAGE TERMINAL ACCESS #
add_terminal_links user_token access_token container_key *links
remove_terminal_links user_token access_token container_key *links
list_terminal_access user_token access_token container_key
edit_terminal_access user_token access_token container_key [options]
  --is_public_list
  --access_rules=value

# MANAGE TERMINAL DNS & DOMAINS #
get_cname_records user_token access_token
add_domain_to_pool user_token access_token domain
remove_domain_from_pool user_token access_token domain
add_cname_record user_token access_token domain subdomain port
remove_cname_record user_token access_token domain

# MANAGE TERMINAL IDLE SETTINGS #
set_terminal_idle_settings user_token access_token container_key action *triggers
get_terminal_idle_settings user_token access_token container_key

# MANAGE USAGE & CREDITS #
instance_types
instance_price instance_type status (defaults to running)
balance user_token access_token
balance_added user_token access_token
gift user_token access_token email cents
burn_history user_token access_token
terminal_usage_history user_token access_token
burn_state user_token access_token
burn_estimates user_token access_token

# MANAGE SSH PUBLIC KEYS #
add_authorized_key_to_terminal user_token access_token container_key publicKey
add_authorized_key_to_ssh_proxy user_token access_token name publicKey
del_authorized_key_from_ssh_proxy user_token access_token name fingerprint
get_authorized_keys_from_ssh_proxy user_token access_token

# OTHER #
who_am_i user_token, access_token
request_progress request_id
