# About

This is a Ruby wrapper for [Terminal.com](https://www.terminal.com) API. It works on Ruby 2; Ruby 1.8 or 1.9 are not supported. It contains:

- Low-level API 1:1 mapping to Terminal.com endpoints.
- High-level object-oriented API.
- Command-line client.

This library has **no dependencies**. You can optionally use it with CodeRay to get syntax-highlighted responses in the command-line client, but the core doesn't depend on any 3rd party library.

It uses `net/http` for network communication. Writing an adapter for a different HTTP library is as simple as overriding one method. In future more HTTP libraries _migth_ be supported.

# Usage

1. Run `gem install terminal.com --development` or put `gem 'terminal.com'` into your Gemfile and run `bundle`. The development option installs coderay, so you get syntax highlighting for JSON on console when using the command-line client.

2. Get your `user_token` and `access_token` from [your settings](https://www.terminal.com/settings/api).

![](docs/terminal-com-api-keys.png)

# API

## Low-Level API

Module methods exposed on the `Terminal` module are 1:1 mapping of the Terminal.com API.

- All the required arguments are translated to positional arguments and comes in the same order as they are listed on the [Terminal.com API docs](https://www.terminal.com/api/docs) page.
- All the optional arguments are specified as options.

### Example

```ruby
require 'terminal.com'

# Let's search featured ruby-related snapshots.
Terminal.list_public_snapshots(tag: 'ruby', featured: true)
# {"snapshots" => [{"title" => "JRuby Stack (example included)", "body" => "JRuby is a 100% Java implementation of the Ruby programming language. This snapshot also includes a working example, its source code and the tools needed to develop JRuby applications.", ...

# List your Terminals.
my_user_token = '...'
my_access_token = '...'

Terminal.list_terminals(my_user_token, my_access_token)
# {"terminals" => [{"cpu" => "2 (max)", "ram" => "256", "diskspace" => "10", "name" => "Coding Interview: John Doe Jr", ...
```

## High-Level `Terminal::API`

Class `Terminal::API` provides abstraction for calls to endpoint that requires authentication. So instead of calling methods on `Terminal` every time with passing `user_token` and `access_token` as arguments, you can just instantiate `Terminal::API` and reuse your credentials.

### Example

```ruby
require 'terminal.com/api'

terminal_com = Terminal::API.new(user_token, access_token)
terminal_com.list_terminals

# Let's start a small instance of the official Ubuntu 14.04 snapshot.
snapshot_id = '987f8d702dc0a6e8158b48ccd3dec24f819a7ccb2756c396ef1fd7f5b34b7980'
terminal_com.start_snapshot(snapshot_id, instance: 'small')
```

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
