# frozen_string_literal: true

require "json"

module NationbuilderApi
  module TokenStorage
    # Redis token storage adapter
    # Stores tokens in Redis with automatic expiry
    class Redis < Base
      KEY_PREFIX = "nationbuilder_api:tokens"

      def initialize(redis_client = nil)
        @redis = redis_client || default_redis_client
      end

      def store_token(identifier, token_data)
        validate_token_data(token_data)

        key = redis_key(identifier)
        serialized = serialize_token_data(token_data)

        @redis.set(key, serialized)
        @redis.expireat(key, token_data[:expires_at].to_i)

        true
      rescue => e
        raise NetworkError, "Redis error: #{e.message}"
      end

      def retrieve_token(identifier)
        key = redis_key(identifier)
        serialized = @redis.get(key)

        return nil unless serialized

        deserialize_token_data(serialized)
      rescue => e
        raise NetworkError, "Redis error: #{e.message}"
      end

      def refresh_token(identifier, new_token_data)
        validate_token_data(new_token_data)

        key = redis_key(identifier)
        existing = retrieve_token(identifier)

        merged_data = existing ? existing.merge(new_token_data) : new_token_data
        serialized = serialize_token_data(merged_data)

        @redis.set(key, serialized)
        @redis.expireat(key, merged_data[:expires_at].to_i)

        true
      rescue => e
        raise NetworkError, "Redis error: #{e.message}"
      end

      def delete_token(identifier)
        key = redis_key(identifier)
        @redis.del(key)

        true
      rescue => e
        raise NetworkError, "Redis error: #{e.message}"
      end

      def self.enabled?
        defined?(::Redis)
      end

      private

      def redis_key(identifier)
        "#{KEY_PREFIX}:#{identifier}"
      end

      def serialize_token_data(token_data)
        data = token_data.dup
        data[:expires_at] = data[:expires_at].iso8601 if data[:expires_at].is_a?(Time)
        JSON.dump(data)
      end

      def deserialize_token_data(serialized)
        data = JSON.parse(serialized, symbolize_names: true)
        data[:expires_at] = Time.parse(data[:expires_at]) if data[:expires_at].is_a?(String)
        data
      end

      def default_redis_client
        if defined?(::Redis)
          ::Redis.new
        else
          raise ConfigurationError, "Redis gem not loaded. Add 'gem \"redis\"' to your Gemfile"
        end
      end
    end
  end
end
