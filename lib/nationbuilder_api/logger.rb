# frozen_string_literal: true

require "logger"
require "json"

module NationbuilderApi
  # Logging wrapper with credential sanitization
  class Logger
    FILTERED = "[FILTERED]"
    SENSITIVE_PATTERNS = [
      /token/i,
      /secret/i,
      /password/i,
      /key/i,
      /authorization/i,
      /^code$/i  # OAuth authorization code parameter
    ].freeze

    def initialize(logger = nil, log_level: :info)
      @logger = logger || default_logger
      @log_level = log_level
      @logger.level = ::Logger.const_get(log_level.to_s.upcase) if @logger.respond_to?(:level=)
    end

    def debug(message)
      @logger.debug(format_message(message))
    end

    def info(message)
      @logger.info(format_message(message))
    end

    def warn(message)
      @logger.warn(format_message(message))
    end

    def error(message)
      @logger.error(format_message(message))
    end

    # Log HTTP request
    def log_request(method, url, headers: {}, body: nil)
      sanitized_url = sanitize_url(url)
      message = "[NationbuilderApi] #{method.upcase} #{sanitized_url}"
      info(message)

      if @log_level == :debug
        debug("  Headers: #{sanitize_hash(headers)}")
        debug("  Body: #{sanitize_body(body)}") if body
      end
    end

    # Log HTTP response
    def log_response(status, duration_ms, headers: {}, body: nil)
      message = "[NationbuilderApi] #{status} (#{duration_ms}ms)"
      info(message)

      if @log_level == :debug
        debug("  Headers: #{sanitize_hash(headers)}")
        debug("  Body: #{sanitize_body(body)}") if body
      end
    end

    # Sanitize sensitive data from hash
    def sanitize_hash(hash)
      return hash unless hash.is_a?(Hash)

      sanitized = {}
      hash.each do |key, value|
        sanitized[key] = sensitive_key?(key) ? FILTERED : value
      end
      sanitized
    end

    # Sanitize sensitive data from body
    def sanitize_body(body)
      return FILTERED unless body

      if body.is_a?(String)
        begin
          parsed = JSON.parse(body)
          JSON.dump(sanitize_hash(parsed))
        rescue JSON::ParserError
          (body.length > 100) ? "#{body[0...100]}..." : body
        end
      elsif body.is_a?(Hash)
        sanitize_hash(body).to_s
      else
        body.to_s
      end
    end

    # Sanitize sensitive query parameters from URL
    def sanitize_url(url)
      return url unless url.include?("?")

      uri = URI.parse(url)
      return url unless uri.query

      # Parse query parameters
      params = URI.decode_www_form(uri.query)

      # Filter sensitive parameters
      sanitized_params = params.map do |key, value|
        [key, sensitive_key?(key) ? FILTERED : value]
      end

      # Rebuild URL with sanitized parameters
      uri.query = URI.encode_www_form(sanitized_params)
      uri.to_s
    rescue URI::InvalidURIError
      # If URL parsing fails, return original (better to log than crash)
      url
    end

    private

    def default_logger
      if defined?(Rails) && Rails.respond_to?(:logger)
        Rails.logger
      else
        ::Logger.new($stdout)
      end
    end

    def format_message(message)
      message.start_with?("[NationbuilderApi]") ? message : "[NationbuilderApi] #{message}"
    end

    def sensitive_key?(key)
      key_str = key.to_s.downcase
      SENSITIVE_PATTERNS.any? { |pattern| key_str.match?(pattern) }
    end
  end
end
