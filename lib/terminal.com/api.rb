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

    def initialize(user_token, access_token)
      @user_token, @access_token = user_token, access_token
    end

    ###############################
    # CREATE AND MANAGE TERMINALS #
    ###############################

    def list_terminals
      Terminal.list_terminals(@user_token, @access_token)
    end

    def get_terminal(**options)
      Terminal.get_terminal(@user_token, @access_token, **options)
    end

    def start_snapshot(snapshot_id, **options)
      if options[:instance]
        unless instance_opts = INSTANCE_TYPES[options[:instance]]
          raise ArgumentError.new("No such instance type: #{options[:instance].inspect}. Instance types are: #{INSTANCE_TYPES.keys.inspect[1..-2]}.")
        end

        options.delete(:instance)
        options.merge!(instance_opts)
      end

      Terminal.start_snapshot(@user_token, @access_token, snapshot_id, **options)
    end

    def delete_terminal(container_key)
      Terminal.delete_terminal(@user_token, @access_token, container_key)
    end

    def restart_terminal(container_key)
      Terminal.restart_terminal(@user_token, @access_token, container_key)
    end

    def pause_terminal(container_key)
      Terminal.pause_terminal(@user_token, @access_token, container_key)
    end

    def resume_terminal(container_key)
      Terminal.resume_terminal(@user_token, @access_token, container_key)
    end

    def edit_terminal(container_key, **options)
      Terminal.edit_terminal(@user_token, @access_token, container_key, **options)
    end

    ###############################
    # CREATE AND MANAGE SNAPSHOTS #
    ###############################

    def list_snapshots(**options)
      Terminal.list_snapshots(@user_token, @access_token, **options)
    end

    def count_snapshots(**options)
      Terminal.count_snapshots(@user_token, @access_token, **options)
    end

    def delete_snapshot(snapshot_id)
      Terminal.delete_snapshot(@user_token, @access_token, snapshot_id)
    end

    def edit_snapshot(snapshot_id, **options)
      Terminal.edit_snapshot(@user_token, @access_token, snapshot_id, **options)
    end

    def snapshot_terminal(container_key, **options)
      Terminal.snapshot_terminal(@user_token, @access_token, container_key, **options)
    end

    ##########################
    # MANAGE TERMINAL ACCESS #
    ##########################

    def add_terminal_links(container_key, *links)
      Terminal.add_terminal_links(@user_token, @access_token, container_key, *links)
    end

    def remove_terminal_links(container_key, *links)
      Terminal.remove_terminal_links(@user_token, @access_token, container_key, *links)
    end

    def list_terminal_access(container_key)
      Terminal.list_terminal_access(@user_token, @access_token, container_key)
    end

    def edit_terminal_access(container_key, **options)
      Terminal.edit_terminal_access(@user_token, @access_token, container_key, **options)
    end

    #################################
    # MANAGE TERMINAL DNS & DOMAINS #
    #################################

    def get_cname_records
      Terminal.get_cname_records(@user_token, @access_token)
    end

    def add_domain_to_pool
      Terminal.add_domain_to_pool(@user_token, @access_token, domain)
    end

    def remove_domain_from_pool
      Terminal.remove_domain_from_pool(@user_token, @access_token, domain)
    end

    def add_cname_record(domain, subdomain, port)
      Terminal.add_cname_record(@user_token, @access_token, domain, subdomain, port)
    end

    def remove_cname_record(domain)
      Terminal.remove_cname_record(@user_token, @access_token, domain)
    end

    #################################
    # MANAGE TERMINAL IDLE SETTINGS #
    #################################

    def set_terminal_idle_settings(container_key, action, *triggers)
      Terminal.set_terminal_idle_settings(@user_token, @access_token, action, *triggers)
    end

    def get_terminal_idle_settings(container_key)
      Terminal.get_terminal_idle_settings(@user_token, @access_token, container_key)
    end

    def balance
      Terminal.balance(@user_token, @access_token)
    end

    def balance_added
      Terminal.balance_added(@user_token, @access_token)
    end

    def gift(email, cents)
      Terminal.gift(@user_token, @access_token, email, cents)
    end

    def burn_history
      Terminal.burn_history(@user_token, @access_token)
    end

    def terminal_usage_history
      Terminal.terminal_usage_history(@user_token, @access_token)
    end

    def burn_state
      Terminal.burn_state(@user_token, @access_token)
    end

    def burn_estimates
      Terminal.burn_estimates(@user_token, @access_token)
    end

    ##########################
    # MANAGE SSH PUBLIC KEYS #
    ##########################

    def add_authorized_key_to_terminal(container_key, publicKey)
      Terminal.add_authorized_key_to_terminal(@user_token, @access_token, container_key, publicKey)
    end

    def add_authorized_key_to_ssh_proxy(name, publicKey)
      Terminal.add_authorized_key_to_ssh_proxy(@user_token, @access_token, name, publicKey)
    end

    def del_authorized_key_from_ssh_proxy(name, fingerprint)
      Terminal.del_authorized_key_from_ssh_proxy(@user_token, @access_token, name, fingerprint)
    end

    def get_authorized_key_from_ssh_proxy
      Terminal.get_authorized_key_from_ssh_proxy(@user_token, @access_token)
    end

    ######################
    # TERMINAL PASSWORDS #
    ######################

    # @since 0.0.4
    def add_terminal_password(container_key, name, password, port)
      Terminal.add_terminal_password(@user_token, @access_token, container_key, name, password, port)
    end

    # @since 0.0.4
    def list_terminal_passwords(container_key)
      Terminal.list_terminal_passwords(@user_token, @access_token, container_key)
    end

    # @since 0.0.4
    def remove_terminal_password(container_key, name)
      Terminal.remove_terminal_password(@user_token, @access_token, container_key, name)
    end

    #########
    # OTHER #
    #########

    def who_am_i
      Terminal.who_am_i(@user_token, @access_token)
    end
  end
end
