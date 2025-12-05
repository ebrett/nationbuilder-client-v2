# frozen_string_literal: true

module NationbuilderApi
  module Resources
    # Base class for API resource wrappers
    # Provides common functionality for making HTTP requests via the client
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      private

      # Make GET request to API
      # @param path [String] API endpoint path
      # @param params [Hash] Query parameters
      # @return [Hash, Array] Parsed response
      def get(path, params: {})
        client.get(path, params: params)
      end

      # Make POST request to API
      # @param path [String] API endpoint path
      # @param body [Hash] Request body
      # @return [Hash, Array] Parsed response
      def post(path, body: {})
        client.post(path, body: body)
      end

      # Make PATCH request to API
      # @param path [String] API endpoint path
      # @param body [Hash] Request body
      # @return [Hash, Array] Parsed response
      def patch(path, body: {})
        client.patch(path, body: body)
      end

      # Make PUT request to API
      # @param path [String] API endpoint path
      # @param body [Hash] Request body
      # @return [Hash, Array] Parsed response
      def put(path, body: {})
        client.put(path, body: body)
      end

      # Make DELETE request to API
      # @param path [String] API endpoint path
      # @return [Hash, Array] Parsed response
      def delete(path)
        client.delete(path)
      end
    end
  end
end
