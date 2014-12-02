require_relative '../terminal.com'

module Terminal
  class API
    # https://www.terminal.com/faq#instanceTypes
    INSTANCE_TYPES = {
      micro:        {cpu: '2 (max)', ram: 256},
      mini:         {cpu: 50,        ram: 800},
      small:        {cpu: 100,       ram: 1600},
      medium:       {cpu: 200,       ram: 3200},
      xlarge:       {cpu: 400,       ram: 6400},
      :'2xlarge' => {cpu: 800,       ram: 12_800},
      :'4xlarge' => {cpu: 1600,      ram: 25_600},
      :'8xlarge' => {cpu: 3200,      ram: 51_200}
    }

    ############################
    # BROWSE SNAPSHOTS & USERS #
    ############################

    def self.get_snapshot(snapshot_id)
      Terminal::API.get_snapshot(snapshot_id)
    end

    def self.get_profile(username)
      Terminal::API.get_profile(username)
    end

    def self.list_public_snapshots(**options)
      Terminal::API.list_public_snapshots(**options)
    end

    def self.count_public_snapshots(**options)
      Terminal::API.count_public_snapshots(**options)
    end

    def get_snapshot(snapshot_id)
      self.class.get_snapshot(snapshot_id)
    end

    def get_profile(username)
      self.class.get_profile(username)
    end

    def list_public_snapshots(**options)
      self.class.list_public_snapshots(**options)
    end

    def count_public_snapshots(**options)
      self.class.count_public_snapshots(**options)
    end

    def initialize(user_token, access_token)
      @user_token, @access_token = user_token, access_token
    end

    ###############################
    # CREATE AND MANAGE TERMINALS #
    ###############################

    def list_terminals
      Terminal::API.list_terminals(@user_token, @access_token)
    end

    def get_terminal(**options)
      Terminal::API.get_terminal(@user_token, @access_token, **options)
    end

    def start_snapshot(snapshot_id, **options)
      if options[:instance]
        unless instance_opts = INSTANCE_TYPES[options[:instance]]
          raise ArgumentError.new("No such instance type: #{options[:instance].inspect}. Instance types are: #{INSTANCE_TYPES.keys.inspect[1..-2]}.")
        end

        options.delete(:instance)
        options.merge!(instance_opts)
      end

      Terminal::API.start_snapshot(@user_token, @access_token, snapshot_id, **options)
    end

    def delete_terminal(container_key)
      Terminal::API.delete_terminal(@user_token, @access_token, container_key)
    end

    def restart_terminal(container_key)
      Terminal::API.restart_terminal(@user_token, @access_token, container_key)
    end

    def pause_terminal(container_key)
      Terminal::API.pause_terminal(@user_token, @access_token, container_key)
    end

    def resume_terminal(container_key)
      Terminal::API.resume_terminal(@user_token, @access_token, container_key)
    end

    def edit_terminal(container_key, **options)
      Terminal::API.edit_terminal(@user_token, @access_token, container_key, **options)
    end

    ###############################
    # CREATE AND MANAGE SNAPSHOTS #
    ###############################

    def list_snapshots(**options)
      Terminal::API.list_snapshots(@user_token, @access_token, **options)
    end

    def count_snapshots(**options)
      Terminal::API.count_snapshots(@user_token, @access_token, **options)
    end

    def delete_snapshot(snapshot_id)
      Terminal::API.delete_snapshot(@user_token, @access_token, snapshot_id)
    end

    def edit_snapshot(snapshot_id, **options)
      Terminal::API.edit_snapshot(@user_token, @access_token, snapshot_id, **options)
    end

    def snapshot_terminal(container_key, **options)
      Terminal::API.snapshot_terminal(@user_token, @access_token, container_key, **options)
    end

    ##########################
    # MANAGE TERMINAL ACCESS #
    ##########################

    def add_terminal_links(container_key, *links)
      Terminal::API.add_terminal_links(@user_token, @access_token, container_key, *links)
    end

    def remove_terminal_links(container_key, *links)
      Terminal::API.remove_terminal_links(@user_token, @access_token, container_key, *links)
    end

    def list_terminal_access(container_key)
      Terminal::API.list_terminal_access(@user_token, @access_token, container_key)
    end

    def edit_terminal_access(container_key, **options)
      Terminal::API.edit_terminal_access(@user_token, @access_token, container_key, **options)
    end

    #################################
    # MANAGE TERMINAL DNS & DOMAINS #
    #################################

    def get_cname_records
      Terminal::API.get_cname_records(@user_token, @access_token)
    end

    def add_domain_to_pool
      Terminal::API.add_domain_to_pool(@user_token, @access_token, domain)
    end

    def remove_domain_from_pool
      Terminal::API.remove_domain_from_pool(@user_token, @access_token, domain)
    end

    def add_cname_record(domain, subdomain, port)
      Terminal::API.add_cname_record(@user_token, @access_token, domain, subdomain, port)
    end

    def remove_cname_record(domain)
      Terminal::API.remove_cname_record(@user_token, @access_token, domain)
    end

    #################################
    # MANAGE TERMINAL IDLE SETTINGS #
    #################################

    def set_terminal_idle_settings(container_key, action, *triggers)
      Terminal::API.set_terminal_idle_settings(@user_token, @access_token, action, *triggers)
    end

    def get_terminal_idle_settings(container_key)
      Terminal::API.get_terminal_idle_settings(@user_token, @access_token, container_key)
    end

    def self.instance_types
      Terminal::API.instance_types
    end

    def self.instance_price(*args)
      Terminal::API.instance_types(*args)
    end

    def instance_types
      self.class.instance_types
    end

    def instance_price(*args)
      self.class.instance_price(*args)
    end

    def balance
      Terminal::API.balance(@user_token, @access_token)
    end

    def balance_added
      Terminal::API.balance_added(@user_token, @access_token)
    end

    def gift(email, cents)
      Terminal::API.gift(@user_token, @access_token, email, cents)
    end

    def burn_history
      Terminal::API.burn_history(@user_token, @access_token)
    end

    def terminal_usage_history
      Terminal::API.terminal_usage_history(@user_token, @access_token)
    end

    def burn_state
      Terminal::API.burn_state(@user_token, @access_token)
    end

    def burn_estimates
      Terminal::API.burn_estimates(@user_token, @access_token)
    end

    ##########################
    # MANAGE SSH PUBLIC KEYS #
    ##########################

    def add_authorized_key_to_terminal(container_key, publicKey)
      Terminal::API.add_authorized_key_to_terminal(@user_token, @access_token, container_key, publicKey)
    end

    def add_authorized_key_to_ssh_proxy(name, publicKey)
      Terminal::API.add_authorized_key_to_ssh_proxy(@user_token, @access_token, name, publicKey)
    end

    def del_authorized_key_from_ssh_proxy(name, fingerprint)
      Terminal::API.del_authorized_key_from_ssh_proxy(@user_token, @access_token, name, fingerprint)
    end

    def get_authorized_key_from_ssh_proxy
      Terminal::API.get_authorized_key_from_ssh_proxy(@user_token, @access_token)
    end

    #########
    # OTHER #
    #########

    def who_am_i
      Terminal::API.who_am_i(@user_token, @access_token)
    end

    def request_progress(request_id)
      Terminal::API.request_progress(request_id)
    end
  end
end
