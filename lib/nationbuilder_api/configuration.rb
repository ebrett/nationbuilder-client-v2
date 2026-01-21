# frozen_string_literal: true

require "uri"
require "logger"

module NationbuilderApi
  class Configuration
    attr_accessor :client_id, :client_secret, :redirect_uri, :base_url,
      :log_level, :timeout, :ssl_verify
    attr_writer :logger, :token_adapter

    DEFAULT_BASE_URL = "https://api.nationbuilder.com/v2"
    DEFAULT_TIMEOUT = 30
    DEFAULT_LOG_LEVEL = :info
    DEFAULT_SSL_VERIFY = true

    def initialize
      @base_url = DEFAULT_BASE_URL
      @timeout = DEFAULT_TIMEOUT
      @log_level = DEFAULT_LOG_LEVEL
      @ssl_verify = DEFAULT_SSL_VERIFY
      @logger = nil
      @token_adapter = nil
      @client_id = nil
      @client_secret = nil
      @redirect_uri = nil
    end

    def validate!
      errors = []

      errors << "client_id is required" if client_id.nil? || client_id.empty?
      errors << "client_secret is required" if client_secret.nil? || client_secret.empty?
      errors << "redirect_uri is required" if redirect_uri.nil? || redirect_uri.empty?

      if redirect_uri && !valid_https_url?(redirect_uri)
        errors << "redirect_uri must be a valid HTTPS URL"
      end

      if base_url && !valid_https_url?(base_url)
        errors << "base_url must be a valid HTTPS URL"
      end

      if timeout && (!timeout.is_a?(Numeric) || timeout <= 0)
        errors << "timeout must be a positive number"
      end

      raise ConfigurationError, "Configuration errors: #{errors.join(", ")}" unless errors.empty?

      true
    end

    def logger
      @logger ||= default_logger
    end

    def token_adapter
      @token_adapter ||= detect_default_adapter
    end

    private

    def valid_https_url?(url)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError
      false
    end

    def default_logger
      if defined?(Rails) && Rails.respond_to?(:logger)
        Rails.logger
      else
        ::Logger.new($stdout).tap do |logger|
          logger.level = ::Logger.const_get(log_level.to_s.upcase)
        end
      end
    end

    def detect_default_adapter
      if defined?(ActiveRecord) && TokenStorage::ActiveRecord.enabled?
        :active_record
      else
        :memory
      end
    end
  end
end
