# This is the low-level version of Terminal.com API.
# All it does is 1:1 mapping of Ruby methods to the API.
#
# Methods that require authentication have a more
# user-friendly, object-oriented API in Terminal::API class.

require 'net/http'
require 'json'
require 'time'

module Terminal

  # The gem version.
  VERSION = '0.0.3'

  # The Terminal.com API version.
  API_VERSION = 'v0.1'

  # The default headers for the requests.
  HEADERS = {'Content-Type' => 'application/json'}

  # Any network error that can potentially occur in Terminal.call
  # should be encapsulated in this. See {Terminal.call} for implementation
  # details.
  #
  # @api plugin
  class NetworkError < StandardError
    attr_reader :original_error

    # @param original_error [Exception] The exception raised by an HTTP library.
    # @see Terminal.call
    def initialize(original_error)
      @original_error = original_error
      super <<-EOF
Network error (#{original_error.class}): #{original_error.message}
      EOF
    end
  end

  # @!group BROWSE SNAPSHOTS & USERS

  # Get information on a snapshot.
  #
  # @param snapshot_id [String] Snapshot ID (the last part of the snapshot URL).
  # @return [Hash] The response data parsed from JSON.
  # @raise [Terminal::NetworkError] Any network-layer error.
  #
  # @example
  #   Terminal.get_snapshot('987f8d702dc0a6e8158b48ccd3dec24f819a7ccb2756c396ef1fd7f5b34b7980')
  #   # {"snapshot" => {"title" => "Official Ubuntu 14.04", "tags" => "ubuntu", "createdAt" => "2014-07-23T20:27:41.743Z", ...}}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#get-snapshot Terminal.com API docs
  def self.get_snapshot(snapshot_id)
    call('/get_snapshot', snapshot_id: snapshot_id)
  end

  # Get information on a user.
  #
  # @param username [String] Any valid username (i. e. `botanicus`).
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   Terminal.get_profile('botanicus')
  #   # {"user" => {"name" => "James C Russell", "url" => "https://twitter.com/botanicus", "location" => "London, UK", ...}}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#get-profile Terminal.com API docs
  def self.get_profile(username)
    call('/get_profile', username: username)
  end

  # Get a count of public snapshots, optionally filtered.
  #
  # @param options [Hash] Filtering options.
  # @option options :username [String] Any valid username (i. e. `botanicus`).
  # @option options :tag [String] Any tag (i. e. `ubuntu`).
  # @option options :featured [true, false] Search only for featured (or non-featured).
  # @option options :title [String] Title to be *matched* against the existing snapshots.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example Count of all the public snapshots.
  #   Terminal.count_public_snapshots
  #   # {"snapshot_count" => 474}
  #
  # @example Count of all the featured snapshots.
  #   Terminal.count_public_snapshots(featured: true)
  #   # {"snapshot_count" => 135}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#count-public-snapshots Terminal.com API docs
  def self.count_public_snapshots(**options)
    ensure_options_validity(options,
      :username, :tag, :featured, :title)

    call('/count_public_snapshots', options)
  end

  # Get a list of public snapshots, optionally filtered
  # and/or paginated.
  #
  # @param options [Hash] Filtering and pagination options.
  # @option options (see .count_public_snapshots)
  # @option options :page [String] Use with `perPage` for pagination.
  # @option options :perPage [String] Use with `page` for pagination.
  # @option options :sortby [String] Either `popularity` or `date`.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example Return all the public snapshots.
  #   Terminal.list_public_snapshots
  #   # {"snapshots" => [{"title" => "Decision Tree", "tags" => "python,ipython", ...}, {...}]}
  #
  # @example Return all the featured snapshots from user botanicus.
  #   Terminal.list_public_snapshots(username: 'botanicus', featured: true)
  #
  # @example Return the first page of the search results with 10 items per page, sorted by date.
  #   Terminal.list_public_snapshots(tag: 'ubuntu', page: 1, perPage: 10, sortby: 'date')
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#list-public-snapshots Terminal.com API docs
  def self.list_public_snapshots(**options)
    ensure_options_validity(options,
      :username, :tag, :featured, :title, :page, :perPage, :sortby)

    call('/list_public_snapshots', options)
  end

  # @!endgroup
  # @!group CREATE AND MANAGE TERMINALS

  # Get a list of all Terminal instances owned by your account.
  #
  # @param user_token [String] Your user token.
  # @param access_token [String] Your access token.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   Terminal.list_terminals(user_token, access_token)
  #   # {"terminals" => [{"name" => "Coding Interview: John Doe Jr", "ram" => "256", ...}, {...}]}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#list-terminals Terminal.com API docs
  def self.list_terminals(user_token, access_token)
    call('/list_terminals',
      user_token: user_token, access_token: access_token)
  end

  # Get info about a Terminal instance of yours. You can
  # specify either `container_key` or `subdomain`.
  #
  # @param (see .list_terminals)
  # @param options [Hash] Provide either `container_key` or `subdomain`.
  # @option options :container_key [String] A valid container key.
  #   You can get it through {.list_terminals}.
  # @option options :subdomain [String] Subdomain of your Terminal (i. e. `johndoe117`).
  #   You can see it in the address bar when you're in the Terminal IDE or through {.list_terminals}.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example Get Terminal info with a container_key.
  #   # Using get_terminal directly with list_terminals doesn't really
  #   # make sense, since you get all the data in list_terminals, so there
  #   # is no need to call get_terminal. This is just to show how you
  #   # can get your container key. It works the same with a subdomain.
  #   terminals = Terminal.list_terminals(user_token, access_token)
  #   container_key = terminals['terminals'].first['container_key']
  #
  #   Terminal.get_terminal(user_token, access_token, container_key: container_key)
  #   # {"terminal" => {"name" => "Coding Interview: John Doe Jr", "ram" => "256", ...}}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#get-terminal Terminal.com API docs
  def self.get_terminal(user_token, access_token, **options)
    ensure_options_validity(options, :container_key, :subdomain)

    options.merge!(user_token: user_token, access_token: access_token)

    call('/get_terminal', options)
  end

  # Start a Terminal instance based on a snapshot.
  #
  # @param (see .list_terminals)
  # @param snapshot_id (see .get_snapshot)
  # @param options [Hash] Configuration of the new Terminal.
  # @option options :cpu [String] How much CPU is required.
  #   Has to be one of the available {https://www.terminal.com/faq#instanceTypes instance types}
  #   and corresponding `:ram` option has to be provided.
  # @option options :ram [String] How much RAM is required.
  #   Has to be one of the available {https://www.terminal.com/faq#instanceTypes instance types}
  #   and corresponding `:cpu` option has to be provided.
  # @option options :temporary [String] If the Terminal is supposed to be temporary or not.
  #   {https://www.terminal.com/faq#temporaryTerminals Temporary Terminals} are automatically
  #   deleted on inactivity.
  # @option options :name [String] Terminal name.
  # @option options :autopause [String] Whether the Terminal should be {https://www.terminal.com/faq#idleSettings auto-paused on inactivity}.
  #   This can be edited later using {.set_terminal_idle_settings}.
  # @option options :startup_script [String] Shell script to be run once the Terminal is ready.
  #   As of now it cannot contain newlines, so setting a different interpreter than `/bin/sh` is impossible.
  # @option options :custom_data [String] Metadata of your Terminal. Anything you need. It will be accessible through {.get_terminal},
  #   but not from within the Terminal itself.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  # @raise [ArgumentError] If either `ram` or `cpu` is specified. These options has to come together.
  #
  # @example
  #   response = Terminal.start_snapshot(user_token, access_token, "57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234", name: "Test")
  #   # {"request_id" => "1418068796272::james@101ideas.cz:create:234509::333c43ab-f6cc-41a3-8307-0fcc4ea3cfb5"}
  #   Terminal.request_progress(response['request_id'])
  #   # {"operation" => "create", "status" => "success", ... }
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#start-snapshot Terminal.com API docs
  # @see https://www.terminal.com/faq#instanceTypes Terminal Instance types
  # @see .edit_terminal
  # @see .set_terminal_idle_settings
  def self.start_snapshot(user_token, access_token, snapshot_id, **options)
    ensure_both_cpu_and_ram_are_provided(options)
    ensure_options_validity(options,
      :cpu, :ram, :temporary, :name, :autopause, :startup_script, :custom_data)

    options.merge!(user_token: user_token, access_token: access_token, snapshot_id: snapshot_id)

    call('/start_snapshot', options)
  end

  # Delete a Terminal instance.
  #
  # @param (see .list_terminals)
  # @param container_key [String] A valid container key.
  #   You can get it through {.list_terminals}.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#delete-terminal Terminal.com API docs
  def self.delete_terminal(user_token, access_token, container_key)
    call('/delete_terminal',
      user_token: user_token, access_token: access_token, container_key: container_key)
  end

  # Reboot a Terminal instance.
  #
  # @param (see .delete_terminal)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#restart-terminal Terminal.com API docs
  def self.restart_terminal(user_token, access_token, container_key)
    call('/restart_terminal',
      user_token: user_token, access_token: access_token, container_key: container_key)
  end

  # Pause a Terminal instance. The instance will be offline
  # and inaccessible, and you will not be charged as long as
  # it remains paused.
  #
  # @param (see .delete_terminal)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#pause-terminal Terminal.com API docs
  def self.pause_terminal(user_token, access_token, container_key)
    call('/pause_terminal',
      user_token: user_token, access_token: access_token, container_key: container_key)
  end

  # Continue running a Terminal instance. The Terminal will
  # continue being charged, and will keep running so long
  # as you maintain a positive balance in your account.
  #
  # @param (see .delete_terminal)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#resume-terminal Terminal.com API docs
  def self.resume_terminal(user_token, access_token, container_key)
    call('/resume_terminal',
      user_token: user_token, access_token: access_token, container_key: container_key)
  end

  # Edit the resources and/or name of a Terminal instance.
  #
  # @param (see .delete_terminal)
  # @param options [Hash] New Terminal configuration.
  # @option options :cpu [String] How much CPU is required.
  #   Has to be one of the available {https://www.terminal.com/faq#instanceTypes instance types}
  #   and corresponding `:ram` option has to be provided.
  #   This option is required.
  # @option options :ram [String] How much RAM is required.
  #   Has to be one of the available {https://www.terminal.com/faq#instanceTypes instance types}
  #   and corresponding `:cpu` option has to be provided.
  #   This option is required.
  # @option options :diskspace [String] How much diskspace is required.
  #   If you want to set to more than 20 GB, you need 25 MB of ram per GB.
  #   This option is required.
  # @option options :name [String] Terminal name.
  # @return (see .get_snapshot)
  # @raise (see .start_snapshot)
  #
  # @example
  #   Terminal.edit_terminal(user_token, access_token, "f9954bd3-5da1-4e17-a688-7791d87ceb6e", cpu: "50", ram: "800", diskspace: "10")
  #   # {"status": "success", "request_id": "1418071005245::james@101ideas.cz:edit:234583::d86c5b44-f716-45d1-85d2-9968fdda15d6"}

  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#edit-terminal Terminal.com API docs
  # @see https://www.terminal.com/faq#instanceTypes Terminal Instance types
  def self.edit_terminal(user_token, access_token, container_key, **options)
    ensure_both_cpu_and_ram_are_provided(options)
    ensure_options_present(options, :cpu, :ram, :diskspace)

    ensure_options_validity(options,
      :cpu, :ram, :diskspace, :name)

    options.merge!(user_token: user_token, access_token: access_token, container_key: container_key)

    call('/edit_terminal', options)
  end

  # @!endgroup
  # @!group CREATE AND MANAGE SNAPSHOTS

  # Get a list of snapshots owned by your account, optionally
  # filtered by the owner's username, a tag, or the snapshot's
  # featured status. You may use a combination of filters.
  #
  # @param (see .list_terminals)
  # @param options [Hash] Filtering and pagination options.
  # @option options (see .list_public_snapshots)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example Return all the snapshots owned by your account.
  #   Terminal.list_snapshots(user_token, access_token)
  #   # {"snapshots" => [{"title" => "Decision Tree", "tags" => "python,ipython", ...}, {...}]}
  #
  # @example Return all the featured snapshots owned by your account.
  #   Terminal.list_snapshots(user_token, access_token, featured: true)
  #
  # @example Return the first page of the search results with 10 items per page, sorted by date.
  #   Terminal.list_snapshots(user_token, access_token, tag: 'ubuntu', page: 1, perPage: 10, sortby: 'date')
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#list-snapshots Terminal.com API docs
  def self.list_snapshots(user_token, access_token, **options)
    ensure_options_validity(options,
      :username, :tag, :featured, :title, :page, :perPage)

    options.merge!(user_token: user_token, access_token: access_token)

    call('/list_snapshots', options)
  end

  # Get a count of snapshots owned by your account, optionally
  # filtered by the owner's username, a tag, or the snapshot's
  # featured status. You may use a combination of filters.
  #
  # @param (see .list_terminals)
  # @param options [Hash] Filtering options.
  # @option options (see .count_public_snapshots)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example Number of all the snapshots owned by your account.
  #   Terminal.count_snapshots(user_token, access_token)
  #   # {"snapshot_count" => 12}
  #
  # @example Number of all the featured snapshots owned by your account.
  #   Terminal.count_public_snapshots(user_token, access_token, featured: true)
  #   # {"snapshot_count" => 2}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#count-snapshots Terminal.com API docs
  def self.count_snapshots(user_token, access_token, **options)
    ensure_options_validity(options,
      :username, :tag, :featured, :title)

    options.merge!(user_token: user_token, access_token: access_token)

    call('/count_snapshots', options)
  end

  # Delete a snapshot from your account. This cannot be undone.
  #
  # @param (see .list_terminals)
  # @param snapshot_id (see .get_snapshot)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#delete-snapshot Terminal.com API docs
  def self.delete_snapshot(user_token, access_token, snapshot_id)
    call('/delete_snapshot',
      user_token: user_token,
      access_token: access_token,
      snapshot_id: snapshot_id)
  end

  # Edit the metadata of a snapshot owned by your account.
  #
  # @param (see .delete_snapshots)
  # @param options [Hash] New snapshot metadata.
  # @option options :body [String] The snapshot description.
  # @option options :title [String] The snapshot title.
  # @option options :readme [String] The README.
  # @option options :tags [String] Comma-separated list of tags (i. e. `ubuntu,ruby`).
  # @option options :public [Boolean] Whether the snapshot will be accessible by other users.
  # @option options :custom_data [String] Metadata of your Terminal. Anything you need.
  #   It will be accessible through {.get_terminal}, but not from within the Terminal itself.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#edit-snapshot Terminal.com API docs
  def self.edit_snapshot(user_token, access_token, snapshot_id, **options)
    ensure_options_validity(options,
      :body, :title, :readme, :tags, :public, :custom_data)

    options.merge!(user_token: user_token, access_token: access_token, snapshot_id: snapshot_id)

    call('/edit_snapshot', options)
  end

  # Create a snapshot of a Terminal instance.
  #
  # @param (see .delete_terminal)
  # @param options [Hash] Snapshot metadata.
  # @option options (see .edit_snapshot)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#snapshot-terminal Terminal.com API docs
  def self.snapshot_terminal(user_token, access_token, container_key, **options)
    ensure_options_validity(options,
      :body, :title, :readme, :tags, :public)

    options.merge!(user_token: user_token, access_token: access_token, container_key: container_key)

    call('/snapshot_terminal', options)
  end

  # @!endgroup
  # @!group MANAGE TERMINAL ACCESS

  # Add to the list of your other Terminals who have access
  # to one of your Terminal instances.
  #
  # Currently this feature doesn't have GUI, so don't be surprised
  # if you haven't come across it yet.
  #
  # @param (see .delete_terminal)
  # @param links [Array<Hash>] Links are hashes with keys `port` and `source`.
  #   Port is any port number and source is any subdomain (i. e. `botanicus117`).
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   container_key = "1123587c-7aec-4b91-90c1-2de534033989"
  #   link = {port: 3000, source: "botanicus117"}
  #   Terminal.add_terminal_links(user_token, access_token, container_key, link)
  #   # {"status":"success"}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#add-terminal-links Terminal.com API docs
  def self.add_terminal_links(user_token, access_token, container_key, *links)
    call('/add_terminal_links',
      user_token: user_token,
      access_token: access_token,
      container_key: container_key,
      links: links)
  end

  # Remove from the list of Terminals who have access to one
  # of your Terminal instances.
  #
  # @param (see .add_terminal_links)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#remove-terminal-links Terminal.com API docs
  def self.remove_terminal_links(user_token, access_token, container_key, *links)
    call('/remove_terminal_links',
      user_token: user_token,
      access_token: access_token,
      container_key: container_key,
      links: links)
  end

  # List users and emails with view or edit access to one
  # of your Terminal instances.
  #
  # @param (see .delete_terminal)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   Terminal.list_terminal_access(user_token, access_token, "268b0082-c96c-4c74-bf0a-a5d6d4c16b01")
  #   # {"is_public_list" => ["80", "3000"],
  #   #  "access_rules" => ["3000::*@cloudlabs.io", "*::james@101ideas.cz", "IDE::james@101ideas.cz", "IDE::terminal@cloudlabs.io"],
  #   #  "links"=>["3000::botanicus117"]}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#list-terminal-access Terminal.com API docs
  # @see https://www.terminal.com/faq#terminalAccess Terminal.com FAQ: Terminal access
  def self.list_terminal_access(user_token, access_token, container_key)
    call('/list_terminal_access',
      user_token: user_token,
      access_token: access_token,
      container_key: container_key)
  end

  # Edit the list of users and emails who have access to one
  # of your Terminal instances.
  #
  # @param (see .delete_terminal)
  # @param options [Hash] Access rules.
  # @option options :is_public_list [Array] List of open ports.
  #   Port `80` is open by default, you can add additional ports.
  # @option options :access_rules [Array] Array of access rules.
  #   An access rule is `<port>::<email>`. Port can be a port number,
  #   `IDE` or an asterisk and email can contain asterisks.
  #   **Examples:** `"3000::*@cloudlabs.io"`, `"*::james@101ideas.cz",
  #   `"IDE::james@101ideas.cz"`.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#edit-terminal-access Terminal.com API docs
  # @see https://www.terminal.com/faq#terminalAccess Terminal.com FAQ: Terminal access
  # @see https://www.terminal.com/faq#openPorts Terminal.com FAQ: Opening additional ports
  def self.edit_terminal_access(user_token, access_token, container_key, **options)
    ensure_options_validity(options, :is_public_list, :access_rules)

    options.merge!(user_token: user_token, access_token: access_token, container_key: container_key)

    call('/edit_terminal_access', options)
  end

  # @!endgroup
  # @!group MANAGE TERMINAL DNS & DOMAINS

  # Get a list of domains in your CNAME record pool. Domains
  # returned by this call can be associated to your Terminal
  # instances.
  #
  # @param (see .list_terminals)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   Terminal.get_cname_records(user_token, access_token)
  #   # {"available" => ["101ideas.cz", "terminal.101ideas.cz"]], "assigned": []}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#get-cname-records Terminal.com API docs
  # @see https://www.terminal.com/faq#cname Terminal.com FAQ: Using my own domains for my Terminals?
  def self.get_cname_records(user_token, access_token)
    call('/get_cname_records',
      user_token: user_token, access_token: access_token)
  end

  # Add a domain or subdomain of Terminal.com to your CNAME
  # record pool, making it available to be associated with
  # one of your Terminal instances.
  #
  # @param (see .list_terminals)
  # @param domain [String] A domain (i. e. `101ideas.cz`).
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#add-domain-to-pool Terminal.com API docs
  # @see https://www.terminal.com/faq#cname Terminal.com FAQ: Using my own domains for my Terminals?
  def self.add_domain_to_pool(user_token, access_token, domain)
    call('/add_domain_to_pool',
      user_token: user_token, access_token: access_token, domain: domain)
  end

  # Remove a domain or subdomain of Terminal.com from your
  # CNAME record pool.
  #
  # @param (see .add_domain_to_pool)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#remove-domain-from-pool Terminal.com API docs
  # @see https://www.terminal.com/faq#cname Terminal.com FAQ: Using my own domains for my Terminals?
  def self.remove_domain_from_pool(user_token, access_token, domain)
    call('/remove_domain_from_pool',
      user_token: user_token, access_token: access_token, domain: domain)
  end

  # Map a domain in your CNAME record pool to one of your
  # Terminal instances, making it accessible via that domain.
  #
  # @param (see .add_domain_to_pool)
  # @param subdomain [String] Subdomain of the Terminal you want the domain assigned to.
  # @param port [String] Which port on the Terminal should it point to?
  #   This will typically be either `80` if you're using Apache or Nginx
  #   or any other number if you're using say Thin or Puma.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   Terminal.add_cname_record(user_token, access_token, 'terminal.101ideas.cz', 'botanicus117', 3000)
  #   # {"available" => [...], "assigned" => [{"domain" => "terminal.101ideas.cz", "subdomain" => "botanicus117", "port" => "3000"}]}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#add-cname-record Terminal.com API docs
  # @see https://www.terminal.com/faq#cname Terminal.com FAQ: Using my own domains for my Terminals?
  def self.add_cname_record(user_token, access_token, domain, subdomain, port)
    call('/add_cname_record',
      user_token: user_token,
      access_token: access_token,
      domain: domain,
      subdomain: subdomain,
      port: port)
  end

  # Remove a domain mapping to one of your Terminal instances.
  # This will mean you can no longer access the Terminal instance
  # from that domain.
  #
  # @param (see .add_domain_to_pool)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#remove-cname-record Terminal.com API docs
  # @see https://www.terminal.com/faq#cname Terminal.com FAQ: Using my own domains for my Terminals?
  def self.remove_cname_record(user_token, access_token, domain)
    call('/remove_cname_record',
      user_token: user_token,
      access_token: access_token,
      domain: domain)
  end

  # @!endgroup
  # @!group MANAGE TERMINAL IDLE SETTINGS

  # Set the {https://www.terminal.com/faq#idleSettings idle settings} for your Terminal.
  #
  # @param (see .delete_terminal)
  # @param action [String] Either `downgrade` or `pause`.
  # @param triggers [Hash<Hash>] Keys can be `cpu_load` or `last_request`.
  #   Keys of those can be `timeout` and `last_request`
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   Terminal.set_terminal_idle_settings(user_token, access_token, 'b878c064-fc2b-4f14-81fa-ca10ac9385ff', 'pause', cpu_load: {timeout: 5600})
  #   # {"success" => true}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#set-terminal-idle-settings Terminal.com API docs
  # @see https://www.terminal.com/faq#idleSettings Terminal.com FAQ: Idle settings
  def self.set_terminal_idle_settings(user_token, access_token, container_key, action, triggers)
    call('/set_terminal_idle_settings',
      user_token: user_token,
      access_token: access_token,
      container_key: container_key,
      action: action,
      triggers: triggers)
  end

  # Get the {https://www.terminal.com/faq#idleSettings idle settings} for your terminal.
  #
  # @param (see .delete_terminal)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   container_key = 'b878c064-fc2b-4f14-81fa-ca10ac9385ff'
  #   Terminal.get_terminal_idle_settings(user_token, access_token, container_key)
  #   # {"success": true,
  #   #  "settings": {
  #   #    "action": "pause",
  #   #    "triggers": {
  #   #      "cpu_load": {
  #   #        "timeout": 3600,
  #   #        "threshold": 10
  #   #      },
  #   #      "last_request": {
  #   #        "timeout": 3600
  #   #      }
  #   #    }
  #   #  }
  #   # }
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#get-terminal-idle-settings Terminal.com API docs
  # @see https://www.terminal.com/faq#idleSettings Terminal.com FAQ: Idle settings
  def self.get_terminal_idle_settings(user_token, access_token, container_key)
    call('/get_terminal_idle_settings',
      user_token: user_token,
      access_token: access_token,
      container_key: container_key)
  end

  # @!endgroup
  # @!group MANAGE USAGE & CREDITS

  # Get a list of the types of Terminals that may be started,
  # and the specifications for each type (CPU, RAM, and pricing).
  #
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   Terminal.instance_types
  #   # {"instance_types" => {
  #   #   "micro" => {"cpu" => "2 (max)", "ram" => 256, "price" => 0.006},
  #   #   "mini" => {"cpu" => 50, "ram" => 800, "price" => 0.031},
  #   #   "small" => {"cpu" => 100, "ram" => 1600, "price" => 0.062},
  #   #   "medium" => {"cpu" => 200, "ram" => 3200, "price" => 0.124},
  #   #   "xlarge" => {"cpu" => 400, "ram" => 6400, "price" => 0.248},
  #   #   "2xlarge" => {"cpu" => 800, "ram" => 12800, "price" => 0.496},
  #   #   "4xlarge" => {"cpu" => 1600, "ram" => 25600, "price" => 0.992},
  #   #   "8xlarge" => {"cpu" => 3200, "ram" => 51200, "price" => 1.984}}}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#instance-types Terminal.com API docs
  def self.instance_types
    call('/instance_types', Hash.new)
  end

  # Get the hourly pricing for a Terminal instance of a given type.
  # If a instance is stopped, price will be zero.
  #
  # @param instance_type [String] desc.
  # @param status [String] Defaults to `running`. It doesn't make
  #   sense to set it to anything else: pause instances are not billed.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   Terminal.instance_price('micro')
  #   # {"price" => 0.006, "units" => "dollars per hour"}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#instance-price Terminal.com API docs
  def self.instance_price(instance_type, status = 'running')
    call('/instance_price', instance_type: instance_type, status: status)
  end

  # Get the current balance of your account.
  #
  # @param (see .list_terminals)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   Terminal.balance(user_token, access_token)
  #   # {"balance" => 675.879}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#balance Terminal.com API docs
  def self.balance(user_token, access_token)
    call('/balance', user_token: user_token, access_token: access_token)
  end

  # Get a history of credits added to your account balance.
  #
  # @param (see .list_terminals)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   Terminal.balance_added(user_token, access_token)
  #   # {"events" => [{"reason" => "Terminal.com sign up gift!", "amount" => 5, "time" => 1411652507924}], "total" => 5}
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#balance-added Terminal.com API docs
  def self.balance_added(user_token, access_token)
    call('/balance_added', user_token: user_token, access_token: access_token)
  end

  # Gift some of your credits to another user. Denominated in whole
  # integer US cents ($0.01). You may only gift credits if you have
  # previously purchased credits.
  #
  # @param (see .list_terminals)
  # @param email [String] User email.
  # @param cents [String] US cents.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#gift Terminal.com API docs
  def self.gift(user_token, access_token, email, cents)
    call('/gift',
      user_token: user_token,
      access_token: access_token,
      email: email,
      cents: cents)
  end

  # Get a history of charges to your account balance.
  #
  # @param (see .list_terminals)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#burn-history Terminal.com API docs
  def self.burn_history(user_token, access_token)
    call('/burn_history', user_token: user_token, access_token: access_token)
  end

  # Get a history of your Terminal usage.
  #
  # @param (see .list_terminals)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#terminal-usage-history Terminal.com API docs
  def self.terminal_usage_history(user_token, access_token)
    call('/terminal_usage_history', user_token: user_token, access_token: access_token)
  end

  # Get a summary of current active charges being billed to your account.
  #
  # @param (see .list_terminals)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#burn-state Terminal.com API docs
  def self.burn_state(user_token, access_token)
    call('/burn_state', user_token: user_token, access_token: access_token)
  end

  # Get a summary of the charges to your account, based on each
  # Terminal instance that you have provisioned. Note that inactive
  # and paused terminals do not incur charges.
  #
  # @param (see .list_terminals)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#burn-estimates Terminal.com API docs
  def self.burn_estimates(user_token, access_token)
    call('/burn_estimates', user_token: user_token, access_token: access_token)
  end

  # @!endgroup
  # @!group MANAGE SSH PUBLIC KEYS

  # Add an SSH public key to a given Terminal's root user.
  #
  # @param (see .delete_terminal)
  # @param publicKey [String] desc.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#add-authorized-key-to-terminal Terminal.com API docs
  # @see https://www.terminal.com/faq#ssh Using SSH to connect to your Terminals
  def self.add_authorized_key_to_terminal(user_token, access_token, container_key, publicKey)
    call('/add_authorized_key_to_terminal',
      user_token: user_token,
      access_token: access_token,
      container_key: container_key,
      publicKey: publicKey)
  end

  # Add an SSH public key to our SSH proxy.
  #
  # @param (see .list_terminals)
  # @param name [String] desc.
  # @param publicKey [String] desc.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#add-authorized-key-to-ssh-proxy Terminal.com API docs
  # @see https://www.terminal.com/faq#ssh Using SSH to connect to your Terminals
  def self.add_authorized_key_to_ssh_proxy(user_token, access_token, name, publicKey)
    call('/add_authorized_key_to_ssh_proxy',
      user_token: user_token,
      access_token: access_token,
      name: name,
      publicKey: publicKey)
  end

  # Delete an SSH public key from our SSH proxy.
  #
  # @param (see .list_terminals)
  # @param name         [String] TODO.
  # @param fingerprint  [String] TODO.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#del-authorized-key-from-ssh-proxy Terminal.com API docs
  # @see https://www.terminal.com/faq#ssh Using SSH to connect to your Terminals
  def self.del_authorized_key_from_ssh_proxy(user_token, access_token, name, fingerprint)
    call('/del_authorized_key_from_ssh_proxy',
      user_token: user_token,
      access_token: access_token,
      name: name,
      fingerprint: fingerprint)
  end

  # List the SSH public key on our SSH proxy.
  #
  # @param (see .list_terminals)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#get-authorized-keys-from-ssh-proxy Terminal.com API docs
  # @see https://www.terminal.com/faq#ssh Using SSH to connect to your Terminals
  def self.get_authorized_keys_from_ssh_proxy(user_token, access_token)
    call('/get_authorized_keys_from_ssh_proxy',
      user_token: user_token, access_token: access_token)
  end

  # @!endgroup
  # @!group TERMINAL PASSWORDS

  # Assign login/password to a Terminal/port combination.
  #
  # @param (see .remove_terminal_password)
  # @param password [String] An arbitrary password.
  # @param port [String] A number, 'IDE' or '*'.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.4
  # @see TODO: So far this is undocumented.
  def self.add_terminal_password(user_token, access_token, container_key, name, password, port)
    call('/add_terminal_password',
      user_token: user_token,
      access_token: access_token,
      container_key: container_key,
      name: name,
      password: password,
      port: port)
  end

  # List all the assigned Terminal logins and the ports they are assigned to.
  #
  # @param (see .delete_terminal)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.4
  # @see TODO: So far this is undocumented.
  def self.list_terminal_passwords(user_token, access_token, container_key)
    call('/list_terminal_passwords',
      user_token: user_token,
      access_token: access_token,
      container_key: container_key)
  end

  # Remove given login/password from a Terminal.
  #
  # @param (see .delete_terminal)
  # @param name [String] An arbitrary identifier.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.4
  # @see TODO: So far this is undocumented.
  def self.remove_terminal_password(user_token, access_token, container_key, name)
    call('/remove_terminal_password',
      user_token: user_token,
      access_token: access_token,
      container_key: container_key,
      name: name)
  end

  # @!endgroup
  # @!group OTHER

  # Get information about yourself!  If invalid access/user token
  # provided, returns null (but not an error).
  #
  # @param (see .list_terminals)
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @example
  #   Terminal.who_am_i(user_token, access_token)
  #   # {
  #   #   "user": {
  #   #     "name": "James C Russell",
  #   #     "username": "botanicus",
  #   #     "url": "https://twitter.com/botanicus",
  #   #     "company": "",
  #   #     "location": "London, United Kingdom",
  #   #     "balance": 675.879,
  #   #     "email": "james@101ideas.cz",
  #   #     "is_admin": false,
  #   #     "profile_image": "//www.gravatar.com/avatar/74c419a50563fa9e5044820c2697ffd6.jpg?s=400&d=mm"
  #   #   }
  #   # }
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#who-am-i Terminal.com API docs
  def self.who_am_i(user_token, access_token)
    call('/who_am_i', user_token: user_token, access_token: access_token)
  end

  # Get info and status of an API request.
  #
  # @param request_id [String] desc.
  # @return (see .get_snapshot)
  # @raise (see .get_snapshot)
  #
  # @since 0.0.1
  # @see https://www.terminal.com/api/docs#request-progress Terminal.com API docs
  def self.request_progress(request_id)
    call('/request_progress', request_id: request_id)
  end

  # @!endgroup
  # @!group IMPLEMENTATION

  # @api private
  def self.request
    @request ||= Net::HTTP.new('api.terminal.com')
  end

  # Make the HTTP call, retrieve and parse the JSON response.
  # Rewrite this method if you wish to use a different HTTP library.
  #
  # @raise [Terminal::NetworkError] Any network-layer error.
  #   It's important that plugins make sure to wrap their potential
  #   exceptions in Terminal::NetworkError for predictable behaviour.
  #
  # @api plugin
  # @since 0.0.1
  def self.call(path, data)
    path = "/#{API_VERSION}#{path}"
    json = data.to_json

    curl_debug(path, data.to_json)

    response = request.post(path, json, HEADERS)
    status   = response.code.to_i

    return parse_json(response.body) if status == 200

    raise "Unexpected status #{status}: #{response.inspect}"
  rescue SocketError => error
    raise NetworkError.new(error)
  end

  # @api private
  def self.curl_debug(path, json)
    return if ENV['DBG'].nil?

    headers = HEADERS.reduce(Array.new) do |buffer, (key, value)|
      buffer << "#{key}: #{value}"
    end.join(' ')

    STDERR.puts <<-EOF
curl -L -X POST -H '#{headers}' -d '#{json}' https://api.terminal.com#{path}
    EOF
  end

  # @api private
  def self.parse_json(json)
    convert_timestamps_to_time(JSON.parse(json))
  end

  # We are ignoring timestamps in arrays since there are none in the API.
  # Also, JSON document doesn't have to be an object, but in Terminal.com API,
  # they all are.
  # @api private
  # TODO: Test it.
  def self.convert_timestamps_to_time(hash)
    hash.each do |key, value|
      if value.is_a?(Hash)
        convert_timestamps_to_time(value)
      elsif value.is_a?(String) && value.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z$/)
        hash[key] = Time.parse(value)
      end
    end
  end

  # @api private
  def self.ensure_options_validity(options, *valid_keys)
    unrecognised_options = (options.keys - valid_keys)

    unless unrecognised_options.empty?
      raise ArgumentError.new("Unrecognised options: #{unrecognised_options.inspect[1..-2]}")
    end
  end

  # @api private
  def self.ensure_both_cpu_and_ram_are_provided(options)
    if (options[:cpu] && ! options[:ram]) || (options[:ram] && ! options[:cpu])
      raise ArgumentError.new('You have to specify both cpu and ram of the corresponding instance type as described at https://www.terminal.com/faq#instanceTypes')
    end
  end

  def self.ensure_options_present(options, *required_keys)
    required_keys.each do |key|
      unless options.has_key?(key)
        raise ArgumentError.new("Option #{key} is required, but is missing.")
      end
    end
  end

  # @!endgroup
end
