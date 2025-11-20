# frozen_string_literal: true

module NationbuilderApi
  module TokenStorage
    # Abstract base class for token storage adapters
    #
    # All adapters must implement:
    # - store_token(identifier, token_data)
    # - retrieve_token(identifier)
    # - refresh_token(identifier, new_token_data)
    # - delete_token(identifier)
    # - self.enabled? (class method)
    #
    # Token data structure:
    # {
    #   access_token: String,
    #   refresh_token: String,
    #   expires_at: Time,
    #   scopes: Array<String>,
    #   token_type: String (default: "Bearer")
    # }
    class Base
      def store_token(identifier, token_data)
        raise NotImplementedError, "#{self.class} must implement #store_token"
      end

      def retrieve_token(identifier)
        raise NotImplementedError, "#{self.class} must implement #retrieve_token"
      end

      def refresh_token(identifier, new_token_data)
        raise NotImplementedError, "#{self.class} must implement #refresh_token"
      end

      def delete_token(identifier)
        raise NotImplementedError, "#{self.class} must implement #delete_token"
      end

      def self.enabled?
        false
      end

      protected

      def validate_token_data(token_data)
        required_keys = [:access_token, :refresh_token, :expires_at, :scopes]
        missing_keys = required_keys - token_data.keys

        unless missing_keys.empty?
          raise ArgumentError, "Missing required token data keys: #{missing_keys.join(", ")}"
        end

        unless token_data[:expires_at].is_a?(Time)
          raise ArgumentError, "expires_at must be a Time object"
        end

        unless token_data[:scopes].is_a?(Array)
          raise ArgumentError, "scopes must be an Array"
        end
      end
    end
  end
end
