# frozen_string_literal: true

module NationbuilderApi
  module Resources
    # Tags API resource
    # Provides access to NationBuilder Tags endpoints for managing tags
    class Tags < Base
      # List all tags
      # Uses V1 API as V2 API does not have tag management endpoints
      #
      # @return [Hash] Tags data in V1 format
      #
      # @example
      #   client.tags.list
      #   # => { results: [{ name: "volunteer", ... }, { name: "donor", ... }] }
      def list
        get("/api/v1/tags")
      end
    end
  end
end
