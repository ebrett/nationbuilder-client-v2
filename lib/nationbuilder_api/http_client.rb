# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module NationbuilderApi
  # HTTP client with automatic authentication and error handling
  class HttpClient
    attr_reader :config, :token_adapter, :identifier

    def initialize(config:, token_adapter:, identifier:, logger: nil)
      @config = config
      @token_adapter = token_adapter
      @identifier = identifier
      @logger = logger || NationbuilderApi::Logger.new(config.logger, log_level: config.log_level)
    end

    # Wrapper class to maintain interface compatibility with http gem responses
    class ResponseWrapper
      attr_reader :body, :headers, :net_http_response

      def initialize(net_http_response)
        @net_http_response = net_http_response
        @body = net_http_response.body
        @headers = net_http_response.to_hash
      end

      def status
        ResponseStatus.new(@net_http_response.code.to_i)
      end
    end

    # Wrapper for response status to provide code attribute
    class ResponseStatus
      attr_reader :code

      def initialize(code)
        @code = code
      end

      def to_i
        @code
      end
    end

    # Make GET request
    def get(path, params: {})
      request(:get, path, params: params)
    end

    # Make POST request
    def post(path, body: {})
      request(:post, path, body: body)
    end

    # Make PATCH request
    def patch(path, body: {})
      request(:patch, path, body: body)
    end

    # Make PUT request
    def put(path, body: {})
      request(:put, path, body: body)
    end

    # Make DELETE request
    def delete(path)
      request(:delete, path)
    end

    private

    def request(method, path, params: {}, body: nil)
      ensure_fresh_token!

      url = build_url(path)
      headers = build_headers
      start_time = Time.now

      @logger.log_request(method, url, headers: headers, body: body)

      response = execute_request(method, url, headers: headers, params: params, body: body)

      duration_ms = ((Time.now - start_time) * 1000).round
      @logger.log_response(response.status, duration_ms, headers: response.headers.to_h, body: response.body.to_s)

      handle_response(response, method, path)
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED => e
      raise NetworkError.new("Network error for #{method.upcase} #{path}: #{e.message}", response: nil)
    end

    def execute_request(method, url, headers:, params:, body:)
      uri = URI(url)

      # Add query parameters for GET requests
      if method == :get && params.any?
        uri.query = URI.encode_www_form(params)
      end

      # Create and configure HTTP client
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = config.timeout
      http.open_timeout = config.timeout

      # Disable SSL verification in development/test environments
      if defined?(Rails) && (Rails.env.development? || Rails.env.test?)
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      # Create request object based on method
      request = case method
      when :get
        Net::HTTP::Get.new(uri)
      when :post
        Net::HTTP::Post.new(uri)
      when :patch
        Net::HTTP::Patch.new(uri)
      when :put
        Net::HTTP::Put.new(uri)
      when :delete
        Net::HTTP::Delete.new(uri)
      else
        raise ArgumentError, "Unsupported HTTP method: #{method}"
      end

      # Set headers
      headers.each { |key, value| request[key] = value }

      # Set body for POST/PATCH/PUT requests
      if body && [:post, :patch, :put].include?(method)
        request.body = JSON.generate(body)
        request["Content-Type"] = "application/json"
      end

      # Execute request and wrap response
      response = http.request(request)
      ResponseWrapper.new(response)
    end

    def build_url(path)
      base = config.base_url.end_with?("/") ? config.base_url[0...-1] : config.base_url
      path = path.start_with?("/") ? path : "/#{path}"
      "#{base}#{path}"
    end

    def build_headers
      token_data = @token_adapter.retrieve_token(@identifier)

      headers = {
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "User-Agent" => "NationbuilderApi/#{NationbuilderApi::VERSION} Ruby/#{RUBY_VERSION}"
      }

      if token_data && token_data[:access_token]
        headers["Authorization"] = "Bearer #{token_data[:access_token]}"
      end

      headers
    end

    def ensure_fresh_token!
      token_data = @token_adapter.retrieve_token(@identifier)
      return unless token_data

      if OAuth.token_expired?(token_data[:expires_at])
        refresh_token!(token_data[:refresh_token])
      end
    end

    def refresh_token!(refresh_token)
      @logger.warn("Refreshing expired access token")

      new_token_data = OAuth.refresh_access_token(
        refresh_token: refresh_token,
        client_id: config.client_id,
        client_secret: config.client_secret,
        oauth_base_url: oauth_base_url
      )

      @token_adapter.refresh_token(@identifier, new_token_data)
    rescue AuthenticationError
      # Refresh token expired or invalid - delete stored token
      @token_adapter.delete_token(@identifier)
      raise
    end

    # Extract OAuth base URL from API base URL
    # Converts "https://api.nationbuilder.com/v2" to "https://api.nationbuilder.com"
    # Converts "https://nation.nationbuilder.com/api/v2" to "https://nation.nationbuilder.com"
    def oauth_base_url
      return nil unless config.base_url

      # Remove API version path to get OAuth base URL
      # Handles both /api/v2 and /v2 patterns
      config.base_url.sub(%r{(/api)?/v\d+/?$}, "")
    end

    def handle_response(response, method, path)
      request_context = "#{method.upcase} #{path}"

      case response.status.code
      when 200..299
        parse_json_response(response)
      when 401
        raise AuthenticationError.new("Authentication failed for #{request_context}", response: response)
      when 403
        raise AuthorizationError.new("Access forbidden for #{request_context}", response: response)
      when 404
        raise NotFoundError.new("Resource not found for #{request_context}", response: response)
      when 422
        raise ValidationError.new("Validation failed for #{request_context}", response: response)
      when 429
        raise RateLimitError.new("Rate limit exceeded for #{request_context}", response: response)
      when 500..599
        raise ServerError.new("Server error for #{request_context}", response: response)
      else
        raise Error.new("HTTP error #{response.status} for #{request_context}", response: response)
      end
    end

    def parse_json_response(response)
      body = response.body.to_s
      return nil if body.empty?

      JSON.parse(body, symbolize_names: true)
    rescue JSON::ParserError => e
      @logger.warn("Failed to parse JSON response: #{e.message}")
      body
    end
  end
end
