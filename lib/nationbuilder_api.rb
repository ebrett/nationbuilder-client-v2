# frozen_string_literal: true

require_relative "nationbuilder_api/version"

module NationbuilderApi
  # Autoload core components
  autoload :Configuration, "nationbuilder_api/configuration"
  autoload :Client, "nationbuilder_api/client"
  autoload :OAuth, "nationbuilder_api/oauth"
  autoload :HttpClient, "nationbuilder_api/http_client"
  autoload :Logger, "nationbuilder_api/logger"

  # Token storage adapters
  module TokenStorage
    autoload :Base, "nationbuilder_api/token_storage/base"
    autoload :Memory, "nationbuilder_api/token_storage/memory"
    autoload :Redis, "nationbuilder_api/token_storage/redis"
    autoload :ActiveRecord, "nationbuilder_api/token_storage/active_record"
  end

  # API resources
  module Resources
    autoload :Base, "nationbuilder_api/resources/base"
    autoload :People, "nationbuilder_api/resources/people"
    autoload :Tags, "nationbuilder_api/resources/tags"
  end

  # OAuth scope constants
  SCOPE_PEOPLE_READ = "people:read"
  SCOPE_PEOPLE_WRITE = "people:write"
  SCOPE_DONATIONS_READ = "donations:read"
  SCOPE_DONATIONS_WRITE = "donations:write"
  SCOPE_EVENTS_READ = "events:read"
  SCOPE_EVENTS_WRITE = "events:write"
  SCOPE_LISTS_READ = "lists:read"
  SCOPE_LISTS_WRITE = "lists:write"
  SCOPE_TAGS_READ = "tags:read"
  SCOPE_TAGS_WRITE = "tags:write"

  class << self
    attr_writer :configuration
    attr_accessor :logger

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

# Load Rails Engine if Rails is present
require "nationbuilder_api/engine" if defined?(Rails::Engine)

# Load errors
require_relative "nationbuilder_api/errors"
