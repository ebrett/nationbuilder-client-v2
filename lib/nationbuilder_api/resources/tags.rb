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

      # Apply a tag to multiple people
      # Uses V1 API for bulk tagging operations
      #
      # @param tag_name [String] Tag name to apply
      # @param person_ids [Array<Integer, String>] Array of person IDs
      # @return [Array<Hash>] Array of responses from API
      #
      # @example
      #   client.tags.bulk_apply("volunteer", [123, 456, 789])
      #   # => [{status: "success"}, {status: "success"}, {status: "success"}]
      def bulk_apply(tag_name, person_ids)
        return [] if person_ids.empty?

        person_ids.map do |person_id|
          put("/api/v1/people/#{person_id}/taggings", body: {tagging: {tag: tag_name}})
        end
      end

      # Remove a tag from multiple people
      # Uses V1 API for bulk tagging operations
      #
      # @param tag_name [String] Tag name to remove
      # @param person_ids [Array<Integer, String>] Array of person IDs
      # @return [Array<Hash>] Array of responses from API
      #
      # @example
      #   client.tags.bulk_remove("volunteer", [123, 456, 789])
      #   # => [{status: "deleted"}, {status: "deleted"}, {status: "deleted"}]
      def bulk_remove(tag_name, person_ids)
        return [] if person_ids.empty?

        person_ids.map do |person_id|
          client.delete("/api/v1/people/#{person_id}/taggings/#{tag_name}")
        end
      end
    end
  end
end
