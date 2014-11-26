require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'fixtures'
  config.hook_into :webmock # or :fakeweb
end
