# frozen_string_literal: true

module NationbuilderApi
  module Resources
    # People API resource
    # Provides access to NationBuilder People endpoints for retrieving person data,
    # taggings, RSVPs, and activities
    class People < Base
      # Fetch a person by ID
      # Uses V2 API with JSON:API format
      #
      # @param id [String, Integer] Person ID or "me" for current user
      # @param include_taggings [Boolean] Whether to sideload taggings (default: false)
      # @return [Hash] Person data in JSON:API format
      #
      # @example
      #   client.people.show(123)
      #   # => { data: { type: "signups", id: "123", attributes: { ... } } }
      #
      # @example With taggings sideloaded
      #   client.people.show(123, include_taggings: true)
      #   # => { data: { ... }, included: [{ type: "tagging", ... }] }
      #
      # @example Current user
      #   client.people.show("me")
      #   # => { data: { type: "signups", id: "123", attributes: { ... } } }
      def show(id, include_taggings: false)
        path = "/api/v2/signups/#{id}"
        path += "?include=taggings" if include_taggings
        get(path)
      end

      # Fetch a person's taggings (subscriptions/lists)
      # Uses V2 API with JSON:API format via sideloading on the person endpoint
      #
      # Note: V2 API returns tagging IDs but does not include tag names.
      # For tag names and tag management, use list_taggings, add_tagging, and remove_tagging (V1 API).
      #
      # @param id [String, Integer] Person ID
      # @return [Hash] Person data with taggings in JSON:API format
      #
      # @example
      #   client.people.taggings(123)
      #   # => { data: { ... }, included: [{ type: "tagging", ... }] }
      def taggings(id)
        show(id, include_taggings: true)
      end

      # List a person's taggings with tag names
      # Uses V1 API which returns tag names (unlike V2 API which only returns IDs)
      #
      # @param id [String, Integer] Person ID
      # @return [Hash] Taggings data with tag names in V1 format
      #
      # @example
      #   client.people.list_taggings(123)
      #   # => { taggings: [{ tag: "volunteer", person_id: 123 }, { tag: "donor", person_id: 123 }] }
      def list_taggings(id)
        get("/api/v1/people/#{id}/taggings")
      end

      # Add a tag to a person
      # Uses V1 API for tag management
      #
      # @param id [String, Integer] Person ID
      # @param tag_name [String] Tag name to add
      # @return [Hash] Response from API
      #
      # @example
      #   client.people.add_tagging(123, "volunteer")
      def add_tagging(id, tag_name)
        put("/api/v1/people/#{id}/taggings", body: {tagging: {tag: tag_name}})
      end

      # Remove a tag from a person
      # Uses V1 API for tag management
      #
      # @param id [String, Integer] Person ID
      # @param tag_name [String] Tag name to remove
      # @return [Hash] Response from API
      #
      # @example
      #   client.people.remove_tagging(123, "volunteer")
      def remove_tagging(id, tag_name)
        delete("/api/v1/people/#{id}/taggings/#{tag_name}")
      end

      # Fetch a person's event RSVPs
      # Uses V2 API with JSON:API format and filters by person_id
      #
      # @param id [String, Integer] Person ID
      # @param include_event [Boolean] Whether to include event details (default: true)
      # @return [Hash] Event RSVPs data in JSON:API format
      #
      # @example
      #   client.people.rsvps(123)
      #   # => { data: [...], included: [...] }
      def rsvps(id, include_event: true)
        params = {filter: {person_id: id}}
        params[:include] = "event" if include_event

        # Build query string manually for nested filter parameter
        query_string = build_query_string(params)
        get("/api/v2/event_rsvps?#{query_string}")
      end

      # Fetch a person's recent activities
      # Note: Uses V1 API as activities endpoint is not yet available in V2
      # This endpoint may not be available on all NationBuilder accounts
      #
      # @param id [String, Integer] Person ID
      # @return [Hash] Activities data with results array (V1 format)
      # @raise [NotFoundError] If activities endpoint is not available
      #
      # @example
      #   client.people.activities(123)
      #   # => { results: [{ type: "email_sent", created_at: "...", ... }, ...] }
      def activities(id)
        # TODO: Migrate to V2 when activities endpoint becomes available
        get("/api/v1/people/#{id}/activities")
      end

      # Update a person's attributes
      # Uses V2 API with JSON:API format
      #
      # @param id [String, Integer] Person ID
      # @param attributes [Hash] Person attributes to update (first_name, last_name, email, phone, mobile, addresses, etc.)
      # @return [Hash] Updated person data in JSON:API format
      # @raise [ValidationError] If attributes are invalid
      # @raise [NotFoundError] If person not found
      # @raise [AuthenticationError] If token is invalid/expired
      #
      # @note This performs a partial update - only provided attributes are modified.
      #   Omitted attributes retain their current values.
      # @note Some fields are read-only (id, created_at, updated_at, etc.)
      #   and will be ignored if included in attributes.
      # @note Some fields may require specific OAuth scopes or account
      #   settings to modify. Check NationBuilder API documentation for details.
      #
      # @example Update basic fields
      #   client.people.update(123, attributes: {
      #     first_name: "John",
      #     last_name: "Doe",
      #     email: "john@example.com",
      #     mobile: "+1234567890"
      #   })
      #
      # @example Update address
      #   client.people.update(123, attributes: {
      #     primary_address: {
      #       address1: "123 Main St",
      #       city: "Portland",
      #       state: "OR",
      #       zip: "97201",
      #       country_code: "US"
      #     }
      #   })
      def update(id, attributes:)
        path = "/api/v2/signups/#{id}"
        body = {
          data: {
            type: "signups",
            id: id.to_s,
            attributes: attributes
          }
        }
        patch(path, body: body)
      end

      private

      # Build query string for complex parameters (like nested filters)
      # Handles nested hashes for filter parameters
      #
      # @param params [Hash] Parameters to convert to query string
      # @return [String] URL-encoded query string
      def build_query_string(params)
        flat_params = flatten_params(params)
        URI.encode_www_form(flat_params)
      end

      # Flatten nested hash parameters for query string
      # Converts { filter: { person_id: 123 } } to { "filter[person_id]" => 123 }
      #
      # @param params [Hash] Nested parameters
      # @param prefix [String, nil] Prefix for nested keys
      # @return [Array<Array>] Flat array of [key, value] pairs
      def flatten_params(params, prefix = nil)
        result = []

        params.each do |key, value|
          full_key = prefix ? "#{prefix}[#{key}]" : key.to_s

          if value.is_a?(Hash)
            result.concat(flatten_params(value, full_key))
          else
            result << [full_key, value]
          end
        end

        result
      end
    end
  end
end
