# frozen_string_literal: true

module NationbuilderApi
  module TokenStorage
    # In-memory token storage adapter
    # Useful for testing and development
    # Not suitable for production use (tokens lost on restart)
    class Memory < Base
      PRODUCTION_WARNING = "TokenStorage::Memory is not suitable for production use. " \
        "Tokens are lost on process restart. " \
        "Use TokenStorage::Redis or TokenStorage::ActiveRecord instead."

      def initialize
        warn_if_production!
        @tokens = {}
        @mutex = Mutex.new
      end

      def store_token(identifier, token_data)
        validate_token_data(token_data)

        @mutex.synchronize do
          @tokens[identifier.to_s] = token_data.dup
        end

        true
      end

      def retrieve_token(identifier)
        @mutex.synchronize do
          @tokens[identifier.to_s]
        end
      end

      def refresh_token(identifier, new_token_data)
        validate_token_data(new_token_data)

        @mutex.synchronize do
          existing = @tokens[identifier.to_s]
          @tokens[identifier.to_s] = if existing
            existing.merge(new_token_data)
          else
            new_token_data.dup
          end
        end

        true
      end

      def delete_token(identifier)
        @mutex.synchronize do
          @tokens.delete(identifier.to_s)
        end

        true
      end

      def self.enabled?
        true
      end

      # Test helper - clear all tokens
      def clear!
        @mutex.synchronize do
          @tokens.clear
        end
      end

      private

      def warn_if_production!
        return unless defined?(Rails) && Rails.env.production?

        logger = NationbuilderApi.logger || NationbuilderApi::Logger.new
        logger.warn(PRODUCTION_WARNING)
      end
    end
  end
end
