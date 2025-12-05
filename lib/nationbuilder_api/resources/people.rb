# frozen_string_literal: true

module NationbuilderApi
  module Resources
    # People API resource
    # Provides access to NationBuilder People endpoints for retrieving person data,
    # taggings, RSVPs, and activities
    class People < Base
      # Fetch a person by ID
      #
      # @param id [String, Integer] Person ID
      # @return [Hash] Person data
      #
      # @example
      #   client.people.show(123)
      #   # => { person: { id: 123, first_name: "John", last_name: "Doe", ... } }
      def show(id)
        get("/api/v1/people/#{id}")
      end

      # Fetch a person's taggings (subscriptions/lists)
      #
      # @param id [String, Integer] Person ID
      # @return [Hash] Taggings data with results array
      #
      # @example
      #   client.people.taggings(123)
      #   # => { results: [{ tag: "volunteer", ... }, ...] }
      def taggings(id)
        get("/api/v1/people/#{id}/taggings")
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
      # Note: This endpoint may not be available on all NationBuilder accounts
      #
      # @param id [String, Integer] Person ID
      # @return [Hash] Activities data with results array
      # @raise [NotFoundError] If activities endpoint is not available
      #
      # @example
      #   client.people.activities(123)
      #   # => { results: [{ type: "email_sent", created_at: "...", ... }, ...] }
      def activities(id)
        get("/api/v1/people/#{id}/activities")
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
