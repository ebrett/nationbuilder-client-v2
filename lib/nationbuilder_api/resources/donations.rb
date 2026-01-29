# frozen_string_literal: true

module NationbuilderApi
  module Resources
    # Donations API resource
    # Provides access to NationBuilder Donations endpoints for managing donations
    class Donations < Base
      # List all donations
      # Uses V2 API with JSON:API format
      #
      # @param page [Integer, nil] Page number for pagination
      # @param per_page [Integer, nil] Number of results per page
      # @param filter [Hash, nil] Filter parameters (e.g., donor_id)
      # @return [Hash] List of donations in JSON:API format
      #
      # @example
      #   client.donations.list
      #   # => { data: [{type: "donation", id: "1", ...}, ...] }
      #
      # @example With pagination
      #   client.donations.list(page: 2, per_page: 50)
      #
      # @example With filtering
      #   client.donations.list(filter: {donor_id: "123"})
      def list(page: nil, per_page: nil, filter: nil)
        params = {}
        params[:page] = {number: page, size: per_page} if page || per_page
        params[:filter] = filter if filter

        get("/api/v2/donations", params: params)
      end

      # Fetch a single donation by ID
      # Uses V2 API with JSON:API format
      #
      # @param id [String, Integer] Donation ID
      # @return [Hash] Donation data in JSON:API format
      #
      # @example
      #   client.donations.show(123)
      #   # => { data: { type: "donation", id: "123", attributes: { ... } } }
      def show(id)
        get("/api/v2/donations/#{id}")
      end

      # Create a new donation
      # Uses V2 API with JSON:API format
      #
      # @param attributes [Hash] Donation attributes (amount_in_cents, donor_id, donated_at, etc.)
      # @return [Hash] Created donation data in JSON:API format
      # @raise [ValidationError] If attributes are invalid
      #
      # @example
      #   client.donations.create(attributes: {
      #     amount_in_cents: 5000,
      #     donor_id: "123",
      #     donated_at: "2025-01-15T10:00:00Z"
      #   })
      def create(attributes:)
        body = {
          data: {
            type: "donations",
            attributes: attributes
          }
        }
        post("/api/v2/donations", body: body)
      end

      # Update a donation
      # Uses V2 API with JSON:API format
      #
      # @param id [String, Integer] Donation ID
      # @param attributes [Hash] Donation attributes to update
      # @return [Hash] Updated donation data in JSON:API format
      # @raise [ValidationError] If attributes are invalid
      # @raise [NotFoundError] If donation not found
      #
      # @example
      #   client.donations.update(123, attributes: {
      #     amount_in_cents: 7500,
      #     note: "Updated donation amount"
      #   })
      def update(id, attributes:)
        body = {
          data: {
            type: "donations",
            id: id.to_s,
            attributes: attributes
          }
        }
        patch("/api/v2/donations/#{id}", body: body)
      end
    end
  end
end
