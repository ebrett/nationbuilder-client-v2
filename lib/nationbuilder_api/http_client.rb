# frozen_string_literal: true

require "http"
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
    rescue HTTP::Error, SocketError, OpenSSL::SSL::SSLError => e
      raise NetworkError.new("Network error for #{method.upcase} #{path}: #{e.message}", response: nil)
    end

    def execute_request(method, url, headers:, params:, body:)
      client = HTTP.timeout(config.timeout).headers(headers)

      case method
      when :get
        client.get(url, params: params)
      when :post
        client.post(url, json: body)
      when :patch
        client.patch(url, json: body)
      when :put
        client.put(url, json: body)
      when :delete
        client.delete(url)
      else
        raise ArgumentError, "Unsupported HTTP method: #{method}"
      end
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
        client_secret: config.client_secret
      )

      @token_adapter.refresh_token(@identifier, new_token_data)
    rescue AuthenticationError
      # Refresh token expired or invalid - delete stored token
      @token_adapter.delete_token(@identifier)
      raise
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
