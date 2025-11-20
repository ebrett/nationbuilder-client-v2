# frozen_string_literal: true

# Coverage reporting
require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/agent-os/"
  minimum_coverage 90
end

require "nationbuilder_api"
require "webmock/rspec"
require "vcr"

# Disable real HTTP connections
WebMock.disable_net_connect!(allow_localhost: false)

# VCR configuration for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data("<NATIONBUILDER_CLIENT_ID>") { ENV["NATIONBUILDER_CLIENT_ID"] }
  config.filter_sensitive_data("<NATIONBUILDER_CLIENT_SECRET>") { ENV["NATIONBUILDER_CLIENT_SECRET"] }
  config.filter_sensitive_data("<ACCESS_TOKEN>") do |interaction|
    interaction.response.headers["Authorization"]&.first
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset configuration before each test
  config.before(:each) do
    NationbuilderApi.reset_configuration!
  end
end
