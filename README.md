# About

This is a Ruby wrapper for [Terminal.com](https://www.terminal.com) API.

At the moment all it does is to dump all the [Terminal.com API endpoints](https://www.terminal.com/api/docs) to `Terminal::API` module, from which you can call them pretty much the same way you'd do with curl, just from Ruby.

In the future there will be more object-oriented abstraction.

# Usage

1. Run `gem install terminal.com` or put `gem 'terminal.com'` into your Gemfile and run `bundle`.

2. Get your `user_token` and `access_token` from [your settings](https://www.terminal.com/settings/api).

![](docs/terminal-com-api-keys.png)

# Example

```ruby
require 'terminal.com'

# Let's search featured ruby-related snapshots.
Terminal::API.list_public_snapshots(tag: 'ruby', featured: true)

# List your Terminals.
my_user_token = '...'
my_access_token = '...'

Terminal::API.list_terminals(my_user_token, my_access_token)
```
