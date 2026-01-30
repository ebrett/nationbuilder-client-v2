# frozen_string_literal: true

module NationbuilderApi
  module Resources
    # Events API resource
    # Provides access to NationBuilder Events endpoints for managing events and RSVPs
    class Events < Base
      # List all events
      # Uses V2 API with JSON:API format
      #
      # @param page [Integer, nil] Page number for pagination
      # @param per_page [Integer, nil] Number of results per page
      # @param filter [Hash, nil] Filter parameters (e.g., status)
      # @return [Hash] List of events in JSON:API format
      #
      # @example
      #   client.events.list
      #   # => { data: [{type: "event", id: "1", ...}, ...] }
      #
      # @example With pagination
      #   client.events.list(page: 2, per_page: 50)
      #
      # @example With filtering
      #   client.events.list(filter: {status: "published"})
      def list(page: nil, per_page: nil, filter: nil)
        params = {}
        params[:page] = {number: page, size: per_page} if page || per_page
        params[:filter] = filter if filter

        get("/api/v2/events", params: params)
      end

      # Fetch a single event by ID
      # Uses V2 API with JSON:API format
      #
      # @param id [String, Integer] Event ID
      # @param include_rsvps [Boolean] Whether to sideload RSVPs (default: false)
      # @return [Hash] Event data in JSON:API format
      #
      # @example
      #   client.events.show(123)
      #   # => { data: { type: "event", id: "123", attributes: { ... } } }
      #
      # @example With RSVPs sideloaded
      #   client.events.show(123, include_rsvps: true)
      #   # => { data: { ... }, included: [{ type: "event_rsvp", ... }] }
      def show(id, include_rsvps: false)
        path = "/api/v2/events/#{id}"
        path += "?include=rsvps" if include_rsvps
        get(path)
      end

      # Create a new event
      # Uses V2 API with JSON:API format
      #
      # @param attributes [Hash] Event attributes (name, start_time, end_time, status, etc.)
      # @return [Hash] Created event data in JSON:API format
      # @raise [ValidationError] If attributes are invalid
      #
      # @example
      #   client.events.create(attributes: {
      #     name: "Fundraising Gala",
      #     start_time: "2025-02-01T18:00:00Z",
      #     end_time: "2025-02-01T22:00:00Z",
      #     status: "published"
      #   })
      def create(attributes:)
        body = {
          data: {
            type: "events",
            attributes: attributes
          }
        }
        post("/api/v2/events", body: body)
      end

      # Update an event
      # Uses V2 API with JSON:API format
      #
      # @param id [String, Integer] Event ID
      # @param attributes [Hash] Event attributes to update
      # @return [Hash] Updated event data in JSON:API format
      # @raise [ValidationError] If attributes are invalid
      # @raise [NotFoundError] If event not found
      #
      # @example
      #   client.events.update(123, attributes: {
      #     name: "Updated Event Name",
      #     status: "published"
      #   })
      def update(id, attributes:)
        body = {
          data: {
            type: "events",
            id: id.to_s,
            attributes: attributes
          }
        }
        patch("/api/v2/events/#{id}", body: body)
      end

      # Delete an event
      # Uses V2 API
      #
      # @param id [String, Integer] Event ID
      # @return [Hash] Response from API
      # @raise [NotFoundError] If event not found
      #
      # @example
      #   client.events.delete(123)
      def delete(id)
        client.delete("/api/v2/events/#{id}")
      end

      # Fetch RSVPs for an event
      # Uses V2 API with JSON:API format
      #
      # @param event_id [String, Integer] Event ID
      # @param include_person [Boolean] Whether to include person data (default: false)
      # @return [Hash] RSVP data in JSON:API format
      #
      # @example
      #   client.events.rsvps(123)
      #   # => { data: [{ type: "event_rsvp", ... }] }
      #
      # @example With person data
      #   client.events.rsvps(123, include_person: true)
      #   # => { data: [...], included: [{ type: "person", ... }] }
      def rsvps(event_id, include_person: false)
        path = "/api/v2/event_rsvps?filter[event_id]=#{event_id}"
        path += "&include=person" if include_person
        get(path)
      end

      # Create an RSVP for an event
      # Uses V2 API with JSON:API format
      #
      # @param event_id [String, Integer] Event ID
      # @param attributes [Hash] RSVP attributes (person_id, status, guests_count, etc.)
      # @return [Hash] Created RSVP data in JSON:API format
      # @raise [ValidationError] If attributes are invalid
      #
      # @example
      #   client.events.create_rsvp(123, attributes: {
      #     person_id: "789",
      #     status: "accepted",
      #     guests_count: 2
      #   })
      def create_rsvp(event_id, attributes:)
        body = {
          data: {
            type: "event_rsvps",
            attributes: attributes.merge(event_id: event_id.to_s)
          }
        }
        post("/api/v2/event_rsvps", body: body)
      end

      # Update an RSVP
      # Uses V2 API with JSON:API format
      #
      # @param rsvp_id [String, Integer] RSVP ID
      # @param attributes [Hash] RSVP attributes to update
      # @return [Hash] Updated RSVP data in JSON:API format
      # @raise [ValidationError] If attributes are invalid
      # @raise [NotFoundError] If RSVP not found
      #
      # @example
      #   client.events.update_rsvp(999, attributes: {
      #     status: "declined",
      #     guests_count: 0
      #   })
      def update_rsvp(rsvp_id, attributes:)
        body = {
          data: {
            type: "event_rsvps",
            id: rsvp_id.to_s,
            attributes: attributes
          }
        }
        patch("/api/v2/event_rsvps/#{rsvp_id}", body: body)
      end

      # Delete an RSVP
      # Uses V2 API
      #
      # @param rsvp_id [String, Integer] RSVP ID
      # @return [Hash] Response from API
      # @raise [NotFoundError] If RSVP not found
      #
      # @example
      #   client.events.delete_rsvp(999)
      def delete_rsvp(rsvp_id)
        client.delete("/api/v2/event_rsvps/#{rsvp_id}")
      end
    end
  end
end
