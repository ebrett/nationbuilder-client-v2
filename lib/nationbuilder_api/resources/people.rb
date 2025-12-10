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
      #   # => { data: { type: "signup", id: "123", attributes: { ... } } }
      #
      # @example With taggings sideloaded
      #   client.people.show(123, include_taggings: true)
      #   # => { data: { ... }, included: [{ type: "tagging", ... }] }
      #
      # @example Current user
      #   client.people.show("me")
      #   # => { data: { type: "signup", id: "123", attributes: { ... } } }
      def show(id, include_taggings: false)
        path = "/api/v2/signups/#{id}"
        path += "?include=taggings" if include_taggings
        get(path)
      end

      # Fetch a person's taggings (subscriptions/lists)
      # Uses V2 API with JSON:API format via sideloading on the person endpoint
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
            type: "signup",
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
