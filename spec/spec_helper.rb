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

  # Enable warnings.
  config.warnings = true

  if config.files_to_run.one?
    # Allow more verbose output when running one file only.
    config.default_formatter = 'doc'
  else
    # Show 3 slowest examples when running the full suite.
    config.profile_examples = 3
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    # be_bigger_than(2).and_smaller_than(4).description
    #   # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #   # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end
end
