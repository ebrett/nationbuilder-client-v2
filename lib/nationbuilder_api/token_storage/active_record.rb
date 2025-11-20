# frozen_string_literal: true

require "json"

module NationbuilderApi
  module TokenStorage
    # ActiveRecord token storage adapter
    # Stores tokens in database table
    #
    # Note: This adapter requires a model with the following structure:
    # - identifier: string (unique index recommended)
    # - access_token: string (or encrypted text)
    # - refresh_token: string (or encrypted text)
    # - expires_at: datetime
    # - scopes: text (JSON array)
    # - token_type: string
    #
    # Phase 1 provides the adapter interface only.
    # Model/migration generation deferred to Phase 4.
    class ActiveRecord < Base
      def initialize(model_class: nil)
        @model_class = model_class || detect_model_class
      end

      def store_token(identifier, token_data)
        validate_token_data(token_data)

        attributes = build_attributes(identifier, token_data)

        # Find existing or create new
        record = @model_class.find_or_initialize_by(identifier: identifier.to_s)
        record.assign_attributes(attributes)
        record.save!

        true
      rescue ::ActiveRecord::RecordInvalid => e
        raise ValidationError, "Failed to store token: #{e.message}"
      rescue => e
        raise Error, "Database error: #{e.message}"
      end

      def retrieve_token(identifier)
        record = @model_class.find_by(identifier: identifier.to_s)
        return nil unless record

        extract_token_data(record)
      rescue => e
        raise Error, "Database error: #{e.message}"
      end

      def refresh_token(identifier, new_token_data)
        validate_token_data(new_token_data)

        record = @model_class.find_by(identifier: identifier.to_s)
        return store_token(identifier, new_token_data) unless record

        attributes = build_attributes(identifier, new_token_data)
        record.update!(attributes)

        true
      rescue ::ActiveRecord::RecordInvalid => e
        raise ValidationError, "Failed to refresh token: #{e.message}", response: nil
      rescue => e
        raise Error, "Database error: #{e.message}"
      end

      def delete_token(identifier)
        record = @model_class.find_by(identifier: identifier.to_s)
        record&.destroy

        true
      rescue => e
        raise Error, "Database error: #{e.message}"
      end

      def self.enabled?
        defined?(::ActiveRecord::Base)
      end

      private

      def detect_model_class
        if defined?(::NationbuilderApiToken)
          ::NationbuilderApiToken
        else
          raise ConfigurationError, "ActiveRecord token model not found. Please configure model_class or define NationbuilderApiToken model"
        end
      end

      def build_attributes(identifier, token_data)
        {
          identifier: identifier.to_s,
          access_token: token_data[:access_token],
          refresh_token: token_data[:refresh_token],
          expires_at: token_data[:expires_at],
          scopes: serialize_scopes(token_data[:scopes]),
          token_type: token_data[:token_type] || "Bearer"
        }
      end

      def extract_token_data(record)
        {
          access_token: record.access_token,
          refresh_token: record.refresh_token,
          expires_at: record.expires_at,
          scopes: deserialize_scopes(record.scopes),
          token_type: record.token_type || "Bearer"
        }
      end

      def serialize_scopes(scopes)
        return scopes if scopes.is_a?(String)
        JSON.dump(scopes)
      end

      def deserialize_scopes(scopes)
        return [] unless scopes
        return scopes if scopes.is_a?(Array)
        JSON.parse(scopes)
      rescue JSON::ParserError
        []
      end
    end
  end
end
