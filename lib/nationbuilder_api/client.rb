# frozen_string_literal: true

module NationbuilderApi
  # Main client class for interacting with NationBuilder API
  class Client
    attr_reader :config, :token_adapter, :identifier

    # Initialize a new client
    #
    # @param options [Hash] Configuration options
    # @option options [String] :client_id OAuth client ID
    # @option options [String] :client_secret OAuth client secret
    # @option options [String] :redirect_uri OAuth callback URL
    # @option options [String] :base_url API base URL (default: https://api.nationbuilder.com/v2)
    # @option options [Symbol, Object] :token_adapter Token storage adapter (:memory, :redis, :active_record, or adapter instance)
    # @option options [Logger] :logger Logger instance
    # @option options [Symbol] :log_level Log level (:debug, :info, :warn, :error)
    # @option options [Integer] :timeout HTTP timeout in seconds
    # @option options [String] :identifier Token identifier for multi-tenant apps
    def initialize(**options)
      @config = build_configuration(options)
      @config.validate!

      @identifier = options[:identifier] || "default"
      @token_adapter = initialize_adapter(options[:token_adapter] || @config.token_adapter)
      @logger = NationbuilderApi::Logger.new(@config.logger, log_level: @config.log_level)
    end

    # Generate OAuth authorization URL with PKCE
    #
    # @param scopes [Array<String>] OAuth scopes
    # @param state [String, nil] CSRF protection token
    # @return [Hash] { url: String, code_verifier: String, state: String }
    def authorize_url(scopes: [], state: nil)
      OAuth.authorization_url(
        client_id: config.client_id,
        redirect_uri: config.redirect_uri,
        scopes: scopes,
        state: state,
        oauth_base_url: oauth_base_url
      )
    end

    # Exchange authorization code for access token
    #
    # @param code [String] Authorization code from OAuth callback
    # @param code_verifier [String] PKCE code verifier from authorize_url
    # @param identifier [String, nil] Token identifier (defaults to client identifier)
    # @return [Hash] Token data
    def exchange_code_for_token(code:, code_verifier:, identifier: nil)
      identifier ||= @identifier

      token_data = OAuth.exchange_code_for_token(
        code: code,
        client_id: config.client_id,
        client_secret: config.client_secret,
        redirect_uri: config.redirect_uri,
        code_verifier: code_verifier,
        oauth_base_url: oauth_base_url,
        logger: @logger
      )

      @token_adapter.store_token(identifier, token_data)
      token_data
    end

    # Manually refresh access token
    #
    # @param identifier [String, nil] Token identifier (defaults to client identifier)
    # @return [Hash] Token data
    def refresh_token(identifier: nil)
      identifier ||= @identifier

      token_data = @token_adapter.retrieve_token(identifier)
      raise AuthenticationError, "No token found for identifier: #{identifier}" unless token_data

      new_token_data = OAuth.refresh_access_token(
        refresh_token: token_data[:refresh_token],
        client_id: config.client_id,
        client_secret: config.client_secret,
        oauth_base_url: oauth_base_url,
        logger: @logger
      )

      @token_adapter.refresh_token(identifier, new_token_data)
      new_token_data
    end

    # Delete stored token
    #
    # @param identifier [String, nil] Token identifier (defaults to client identifier)
    def delete_token(identifier: nil)
      identifier ||= @identifier
      @token_adapter.delete_token(identifier)
    end

    # Make GET request
    #
    # @param path [String] API path
    # @param params [Hash] Query parameters
    # @return [Hash, Array] Parsed response
    def get(path, params: {})
      http_client.get(path, params: params)
    end

    # Make POST request
    #
    # @param path [String] API path
    # @param body [Hash] Request body
    # @return [Hash, Array] Parsed response
    def post(path, body: {})
      http_client.post(path, body: body)
    end

    # Make PATCH request
    #
    # @param path [String] API path
    # @param body [Hash] Request body
    # @return [Hash, Array] Parsed response
    def patch(path, body: {})
      http_client.patch(path, body: body)
    end

    # Make PUT request
    #
    # @param path [String] API path
    # @param body [Hash] Request body
    # @return [Hash, Array] Parsed response
    def put(path, body: {})
      http_client.put(path, body: body)
    end

    # Make DELETE request
    #
    # @param path [String] API path
    # @return [Hash, Array] Parsed response
    def delete(path)
      http_client.delete(path)
    end

    private

    # Extract OAuth base URL from API base URL
    # Converts "https://api.nationbuilder.com/v2" to "https://api.nationbuilder.com"
    # Converts "https://nation.nationbuilder.com/api/v2" to "https://nation.nationbuilder.com"
    def oauth_base_url
      return nil unless config.base_url

      # Remove API version path to get OAuth base URL
      # Handles both /api/v2 and /v2 patterns
      config.base_url.sub(%r{(/api)?/v\d+/?$}, "")
    end

    def build_configuration(options)
      config = Configuration.new

      # Merge global configuration
      global_config = NationbuilderApi.configuration
      config.client_id = global_config.client_id
      config.client_secret = global_config.client_secret
      config.redirect_uri = global_config.redirect_uri
      config.base_url = global_config.base_url
      config.token_adapter = global_config.token_adapter
      config.logger = global_config.logger
      config.log_level = global_config.log_level
      config.timeout = global_config.timeout

      # Override with instance options
      options.each do |key, value|
        config.public_send("#{key}=", value) if config.respond_to?("#{key}=")
      end

      config
    end

    def initialize_adapter(adapter)
      case adapter
      when :memory
        TokenStorage::Memory.new
      when :redis
        TokenStorage::Redis.new
      when :active_record
        TokenStorage::ActiveRecord.new
      when Symbol
        raise ConfigurationError, "Unknown token adapter: #{adapter}"
      else
        # Assume it's an adapter instance
        validate_adapter_interface!(adapter)
        adapter
      end
    end

    def validate_adapter_interface!(adapter)
      required_methods = [:store_token, :retrieve_token, :refresh_token, :delete_token]
      missing_methods = required_methods.reject { |method| adapter.respond_to?(method) }

      unless missing_methods.empty?
        raise ConfigurationError, "Token adapter missing required methods: #{missing_methods.join(", ")}"
      end
    end

    def http_client
      @http_client ||= HttpClient.new(
        config: config,
        token_adapter: @token_adapter,
        identifier: @identifier,
        logger: @logger
      )
    end
  end
end
