# frozen_string_literal: true

module NationbuilderApi
  module ResponseObjects
    # Base class for API response objects
    # Wraps API responses (both V1 and V2 formats) in objects with convenient attribute access
    #
    # @example Using with V2 API (JSON:API format)
    #   response = { data: { type: "signup", id: "123", attributes: { first_name: "John" } } }
    #   person = ResponseObjects::Base.new(response)
    #   person.id          # => "123"
    #   person.first_name  # => "John"
    #   person.to_h        # => original hash
    #
    # @example Using with V1 API (plain JSON)
    #   response = { first_name: "John", last_name: "Doe" }
    #   obj = ResponseObjects::Base.new(response)
    #   obj.first_name  # => "John"
    #   obj.to_h        # => original hash
    class Base
      attr_reader :raw_data

      # Initialize response object with raw API response
      #
      # @param data [Hash] Raw API response (V1 or V2 format)
      def initialize(data)
        @raw_data = data
        @attributes = extract_attributes(data)
      end

      # Get original hash representation
      #
      # @return [Hash] Original API response
      def to_h
        raw_data
      end

      # Get attributes as hash
      #
      # @return [Hash] Flattened attributes
      attr_reader :attributes

      # Access attributes via method calls
      #
      # @param method_name [Symbol] Attribute name
      # @param args [Array] Method arguments (unused)
      # @return [Object] Attribute value
      def method_missing(method_name, *args)
        return @attributes[method_name] if @attributes.key?(method_name)
        return @attributes[method_name.to_s] if @attributes.key?(method_name.to_s)

        super
      end

      # Check if object responds to method
      #
      # @param method_name [Symbol] Method name
      # @param include_private [Boolean] Include private methods
      # @return [Boolean] True if responds to method
      def respond_to_missing?(method_name, include_private = false)
        @attributes.key?(method_name) || @attributes.key?(method_name.to_s) || super
      end

      # Check equality based on raw data
      #
      # @param other [Object] Other object to compare
      # @return [Boolean] True if equal
      def ==(other)
        return false unless other.is_a?(self.class)
        raw_data == other.raw_data
      end

      # Hash-like access to support backward compatibility
      #
      # @param key [Symbol, String] Key to access
      # @return [Object] Value at key
      def [](key)
        raw_data[key]
      end

      # Get all keys from raw data
      #
      # @return [Array] Array of keys
      def keys
        raw_data.keys
      end

      # Get all values from raw data
      #
      # @return [Array] Array of values
      def values
        raw_data.values
      end

      # Check if key exists in raw data
      #
      # @param key [Symbol, String] Key to check
      # @return [Boolean] True if key exists
      def key?(key)
        raw_data.key?(key)
      end

      # Iterate over raw data
      #
      # @yield [key, value] Yields key-value pairs
      def each(&block)
        raw_data.each(&block)
      end

      # Support dig for nested access
      #
      # @param keys [Array] Keys to dig through
      # @return [Object] Value at nested key path
      def dig(*keys)
        raw_data.dig(*keys)
      end

      private

      # Extract attributes from response based on format
      # Handles both V2 (JSON:API) and V1 (plain JSON) formats
      #
      # @param data [Hash] Raw response data
      # @return [Hash] Extracted attributes
      def extract_attributes(data)
        if jsonapi_format?(data)
          extract_jsonapi_attributes(data)
        else
          # V1 format or plain hash - use as-is
          data.transform_keys(&:to_sym)
        end
      end

      # Check if response is JSON:API format
      #
      # @param data [Hash] Response data
      # @return [Boolean] True if JSON:API format
      def jsonapi_format?(data)
        data.is_a?(Hash) && data.key?(:data) && data[:data].is_a?(Hash)
      end

      # Extract attributes from JSON:API formatted response
      #
      # @param data [Hash] JSON:API response
      # @return [Hash] Flattened attributes with id and type
      def extract_jsonapi_attributes(data)
        resource = data[:data]
        attrs = resource[:attributes] || {}

        # Include id and type from resource level
        attrs = attrs.merge(
          id: resource[:id],
          type: resource[:type]
        )

        # Handle relationships if present
        if resource[:relationships]
          attrs[:relationships] = resource[:relationships]
        end

        # Include any sideloaded data
        if data[:included]
          attrs[:included] = data[:included]
        end

        attrs.transform_keys(&:to_sym)
      end
    end
  end
end
