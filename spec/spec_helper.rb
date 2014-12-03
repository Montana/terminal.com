require 'vcr'
require 'yaml'

require 'terminal.com'

ENV['DBG'] = 'curl'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/low-level/fixtures'
  config.hook_into :webmock # or :fakeweb
end

RSpec.configure do |config|
  config.include Module.new {
    def credentials
      @credentials ||= YAML.load_file('spec/credentials.yml')
    end

    def user_token
      credentials[:user_token]
    end

    def access_token
      credentials[:access_token]
    end

    def ubuntu_snap_id
      '987f8d702dc0a6e8158b48ccd3dec24f819a7ccb2756c396ef1fd7f5b34b7980'
    end
  }

  #
  # See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
  #

  # Run only examples tagged with :focus or, if none, everything.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
end
