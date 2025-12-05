# frozen_string_literal: true

require "net/http"
require "uri"

module NationbuilderApi
  # Low-level HTTP request module shared by OAuth and HttpClient
  # Provides consistent logging and error handling for all HTTP operations
  module HttpRequest
    class << self
      # Make an HTTP POST request with form data
      #
      # @param url [String] Full URL for the request
      # @param params [Hash] Form parameters
      # @param timeout [Integer] Timeout in seconds (default: 30)
      # @param logger [Logger, nil] Logger instance for request/response logging
      # @return [Net::HTTPResponse] Raw HTTP response
      # @raise [NetworkError] On network or timeout errors
      def post_form(url, params, timeout: 30, logger: nil)
        uri = URI(url)
        start_time = Time.now

        # Log request if logger provided
        logger&.log_request(:post, url, headers: {"Content-Type" => "application/x-www-form-urlencoded"}, body: params)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = timeout
        http.open_timeout = timeout
        # SSL verification is always enabled for security

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/x-www-form-urlencoded"
        request.set_form_data(params)

        response = http.request(request)

        # Log response if logger provided
        if logger
          duration_ms = ((Time.now - start_time) * 1000).round
          logger.log_response(response.code.to_i, duration_ms, headers: response.to_hash, body: response.body)
        end

        response
      rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED => e
        raise NetworkError.new("Network error for POST #{url}: #{e.message}", response: nil)
      end
    end
  end
end
