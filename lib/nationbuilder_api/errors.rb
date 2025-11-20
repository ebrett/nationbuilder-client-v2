# frozen_string_literal: true

module NationbuilderApi
  # Base error class for all NationBuilder API errors
  class Error < StandardError
    attr_reader :response, :error_code, :error_message

    def initialize(message = nil, response: nil)
      @response = response
      if response
        parse_error_details(response)
        super(message || @error_message || "An error occurred")
      else
        super(message)
      end
    end

    def retryable?
      false
    end

    private

    def parse_error_details(response)
      return unless response

      # Try to parse JSON error response
      if response.respond_to?(:body)
        body = response.body
        if body.is_a?(String)
          begin
            parsed = JSON.parse(body)
            @error_code = parsed["code"] || parsed["error"]
            @error_message = parsed["message"] || parsed["error_description"]
          rescue JSON::ParserError
            @error_message = body
          end
        elsif body.is_a?(Hash)
          @error_code = body[:code] || body["code"] || body[:error] || body["error"]
          @error_message = body[:message] || body["message"] || body[:error_description] || body["error_description"]
        end
      end
    end
  end

  # Configuration errors (missing/invalid configuration)
  class ConfigurationError < Error
    def retryable?
      false
    end
  end

  # Authentication errors (OAuth/token failures)
  class AuthenticationError < Error
    def retryable?
      false
    end
  end

  # Authorization errors (permission/scope issues)
  class AuthorizationError < Error
    def retryable?
      false
    end
  end

  # Validation errors (invalid request parameters)
  class ValidationError < Error
    def retryable?
      false
    end
  end

  # Resource not found errors
  class NotFoundError < Error
    def retryable?
      false
    end
  end

  # Rate limit errors (429 responses)
  class RateLimitError < Error
    attr_reader :retry_after

    def initialize(message = nil, response: nil, retry_after: nil)
      @retry_after = retry_after || parse_retry_after(response)
      super(message || "Rate limit exceeded. Retry after #{@retry_after}", response: response)
    end

    def retryable?
      true
    end

    private

    def parse_retry_after(response)
      return nil unless response

      # Try Retry-After header
      if response.respond_to?(:headers)
        retry_after_header = response.headers["Retry-After"] || response.headers["retry-after"]
        if retry_after_header
          # Could be seconds (integer) or HTTP date
          return Time.now + retry_after_header.to_i if /^\d+$/.match?(retry_after_header)
          begin
            return Time.parse(retry_after_header)
          rescue
            nil
          end
        end

        # Try X-RateLimit-Reset header (Unix timestamp)
        reset_header = response.headers["X-RateLimit-Reset"] || response.headers["x-ratelimit-reset"]
        return Time.at(reset_header.to_i) if reset_header
      end

      # Default: retry after 60 seconds
      Time.now + 60
    end
  end

  # Server errors (5xx responses)
  class ServerError < Error
    def retryable?
      true
    end
  end

  # Network errors (timeouts, connection failures)
  class NetworkError < Error
    def retryable?
      true
    end
  end
end
