# frozen_string_literal: true

require "securerandom"
require "digest/sha2"
require "base64"
require "uri"
require "json"
require "net/http"

module NationbuilderApi
  # OAuth 2.0 with PKCE implementation
  module OAuth
    # Default OAuth URLs (can be overridden with oauth_base_url parameter)
    DEFAULT_OAUTH_BASE_URL = "https://nationbuilder.com"
    AUTHORIZATION_URL = "#{DEFAULT_OAUTH_BASE_URL}/oauth/authorize"
    TOKEN_URL = "#{DEFAULT_OAUTH_BASE_URL}/oauth/token"

    VERIFIER_LENGTH = 64 # 43-128 characters allowed, 64 is a good default

    class << self
      # Generate PKCE code verifier
      # Returns a URL-safe random string of 43-128 characters
      def generate_code_verifier
        SecureRandom.urlsafe_base64(VERIFIER_LENGTH).tr("+/", "-_").tr("=", "")[0...VERIFIER_LENGTH]
      end

      # Generate PKCE code challenge from verifier
      # Uses S256 method (SHA256 hash, Base64 URL-safe encoded)
      def generate_code_challenge(code_verifier)
        digest = Digest::SHA256.digest(code_verifier)
        Base64.urlsafe_encode64(digest).tr("=", "")
      end

      # Generate authorization URL with PKCE
      #
      # @param client_id [String] OAuth client ID
      # @param redirect_uri [String] OAuth callback URL
      # @param scopes [Array<String>] OAuth scopes
      # @param state [String, nil] CSRF protection token
      # @param code_verifier [String, nil] PKCE code verifier (generated if not provided)
      # @param oauth_base_url [String, nil] Base URL for OAuth endpoints (e.g., "https://yournation.nationbuilder.com")
      # @return [Hash] { url: String, code_verifier: String, state: String }
      def authorization_url(client_id:, redirect_uri:, scopes: [], state: nil, code_verifier: nil, oauth_base_url: nil)
        code_verifier ||= generate_code_verifier
        code_challenge = generate_code_challenge(code_verifier)
        state ||= SecureRandom.urlsafe_base64(32)

        params = {
          client_id: client_id,
          redirect_uri: redirect_uri,
          response_type: "code",
          code_challenge: code_challenge,
          code_challenge_method: "S256",
          state: state
        }

        params[:scope] = scopes.join(" ") unless scopes.empty?

        # Use nation-specific OAuth URL if provided, otherwise fall back to default
        auth_url = oauth_base_url ? "#{oauth_base_url}/oauth/authorize" : AUTHORIZATION_URL
        url = "#{auth_url}?#{URI.encode_www_form(params)}"

        {
          url: url,
          code_verifier: code_verifier,
          state: state
        }
      end

      # Exchange authorization code for access token
      #
      # @param code [String] Authorization code from OAuth callback
      # @param client_id [String] OAuth client ID
      # @param client_secret [String] OAuth client secret
      # @param redirect_uri [String] OAuth callback URL (must match authorization)
      # @param code_verifier [String] PKCE code verifier
      # @param oauth_base_url [String, nil] Base URL for OAuth endpoints (e.g., "https://yournation.nationbuilder.com")
      # @return [Hash] Token data
      def exchange_code_for_token(code:, client_id:, client_secret:, redirect_uri:, code_verifier:, oauth_base_url: nil)
        params = {
          grant_type: "authorization_code",
          code: code,
          redirect_uri: redirect_uri,
          client_id: client_id,
          client_secret: client_secret,
          code_verifier: code_verifier
        }

        # Use nation-specific OAuth URL if provided, otherwise fall back to default
        token_url = oauth_base_url ? "#{oauth_base_url}/oauth/token" : TOKEN_URL
        response = make_token_request(token_url, params)

        parse_token_response(response)
      end

      # Refresh access token using refresh token
      #
      # @param refresh_token [String] Refresh token
      # @param client_id [String] OAuth client ID
      # @param client_secret [String] OAuth client secret
      # @param oauth_base_url [String, nil] Base URL for OAuth endpoints (e.g., "https://yournation.nationbuilder.com")
      # @return [Hash] Token data
      def refresh_access_token(refresh_token:, client_id:, client_secret:, oauth_base_url: nil)
        params = {
          grant_type: "refresh_token",
          refresh_token: refresh_token,
          client_id: client_id,
          client_secret: client_secret
        }

        # Use nation-specific OAuth URL if provided, otherwise fall back to default
        token_url = oauth_base_url ? "#{oauth_base_url}/oauth/token" : TOKEN_URL
        response = make_token_request(token_url, params)

        parse_token_response(response)
      end

      # Check if token is expired or expiring soon
      #
      # @param expires_at [Time] Token expiry time
      # @param buffer_seconds [Integer] Refresh buffer (default: 60 seconds)
      # @return [Boolean] True if token needs refresh
      def token_expired?(expires_at, buffer_seconds: 60)
        return true unless expires_at
        expires_at <= Time.now + buffer_seconds
      end

      private

      # Make HTTP POST request for token exchange
      # Uses Net::HTTP with SSL configuration
      def http_client
        # This method name is kept for compatibility but now creates a Net::HTTP request
        # The actual POST is done in the make_token_request method
        self
      end

      def make_token_request(url, params)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 30
        http.open_timeout = 30

        # Disable SSL verification in development/test environments
        if defined?(Rails) && (Rails.env.development? || Rails.env.test?)
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/x-www-form-urlencoded"
        request.set_form_data(params)

        http.request(request)
      end

      def parse_token_response(response)
        unless response.is_a?(Net::HTTPSuccess)
          error_message = extract_error_message(response)
          raise AuthenticationError.new(error_message, response: response)
        end

        body = JSON.parse(response.body, symbolize_names: true)

        {
          access_token: body[:access_token],
          refresh_token: body[:refresh_token],
          expires_at: Time.now + body[:expires_in].to_i,
          scopes: parse_scopes(body[:scope]),
          token_type: body[:token_type] || "Bearer"
        }
      rescue JSON::ParserError => e
        raise AuthenticationError.new("Invalid token response: #{e.message}", response: response)
      end

      def parse_scopes(scope_string)
        return [] unless scope_string
        scope_string.split(" ")
      end

      def extract_error_message(response)
        body = JSON.parse(response.body, symbolize_names: true)
        body[:error_description] || body[:error] || "OAuth error"
      rescue JSON::ParserError
        "OAuth error: #{response.code} #{response.message}"
      end
    end
  end
end
