# About

This is a Ruby wrapper for [Terminal.com](https://www.terminal.com) API. Works on Ruby 2, Ruby 1.8 or 1.9 are not supported.

At the moment all it does is to dump all the [Terminal.com API endpoints](https://www.terminal.com/api/docs) to `Terminal::API` module, from which you can call them pretty much the same way you'd do with curl, just from Ruby.

In the future there will be more object-oriented abstraction.

# Usage

1. Run `gem install terminal.com --development` or put `gem 'terminal.com'` into your Gemfile and run `bundle`. The development option installs coderay, so you get syntax highlighting for JSON on console when using the command-line client.

2. Get your `user_token` and `access_token` from [your settings](https://www.terminal.com/settings/api).

![](docs/terminal-com-api-keys.png)

# Command-Line Client

Anything you can do from the library can be done through the CLI client. There are two ways how you can use it.

![](docs/terminal-cli-client.png)

## Without Configuration

```bash
terminal.com [user_token] [access_token] list_terminals
```

*Note that at the point you have to provide both `user_token` and `access_token` regardless of whether the API endpoint actually needs it. This will be fixed in near future!*

## With Configuration

Specifying the credentials every single time can be quite tedious. That's where `terminal.com configure` comes in handy:

![](docs/terminal-com-configure.png)

```bash
# One time only.
terminal.com configure

# Now you can simply do:
terminal.com list_terminals
```

## Options

```bash
terminal.com list_public_snapshots --tag=ruby --featured
```

# Example

```ruby
require 'terminal.com'

# Let's search featured ruby-related snapshots.
Terminal::API.list_public_snapshots(tag: 'ruby', featured: true)
# {"snapshots" => [{"title" => "JRuby Stack (example included)", "body" => "JRuby is a 100% Java implementation of the Ruby programming language. This snapshot also includes a working example, its source code and the tools needed to develop JRuby applications.", ...

# List your Terminals.
my_user_token = '...'
my_access_token = '...'

Terminal::API.list_terminals(my_user_token, my_access_token)
# {"terminals" => [{"cpu" => "2 (max)", "ram" => "256", "diskspace" => "10", "name" => "Coding Interview: John Doe Jr", ...
```
