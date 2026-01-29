# frozen_string_literal: true

RSpec.describe NationbuilderApi::Resources::People do
  let(:config) do
    instance_double(
      NationbuilderApi::Configuration,
      wrap_responses: false
    )
  end

  let(:client) do
    instance_double(
      NationbuilderApi::Client,
      get: nil,
      post: nil,
      patch: nil,
      delete: nil,
      config: config
    )
  end

  subject(:people) { described_class.new(client) }

  describe "#show" do
    it "makes GET request to /api/v2/signups/:id" do
      expect(client).to receive(:get).with("/api/v2/signups/123", params: {})
      people.show(123)
    end

    it "returns person data in JSON:API format" do
      person_data = {
        data: {
          type: "signup",
          id: "123",
          attributes: {
            first_name: "John",
            last_name: "Doe",
            email: "john@example.com"
          }
        }
      }

      allow(client).to receive(:get).and_return(person_data)
      result = people.show(123)

      expect(result).to eq(person_data)
    end

    it "accepts string ID" do
      expect(client).to receive(:get).with("/api/v2/signups/456", params: {})
      people.show("456")
    end

    it "includes taggings when requested" do
      expect(client).to receive(:get).with("/api/v2/signups/123?include=taggings", params: {})
      people.show(123, include_taggings: true)
    end

    it "supports 'me' for current user" do
      expect(client).to receive(:get).with("/api/v2/signups/me", params: {})
      people.show("me")
    end
  end

  describe "#taggings" do
    it "makes GET request to /api/v2/signups/:id with taggings included" do
      expect(client).to receive(:get).with("/api/v2/signups/123?include=taggings", params: {})
      people.taggings(123)
    end

    it "returns person data with taggings in JSON:API format" do
      taggings_data = {
        data: {
          type: "signup",
          id: "123",
          attributes: {first_name: "John"}
        },
        included: [
          {type: "tagging", id: "1", attributes: {tag: "volunteer"}},
          {type: "tagging", id: "2", attributes: {tag: "donor"}}
        ]
      }

      allow(client).to receive(:get).and_return(taggings_data)
      result = people.taggings(123)

      expect(result).to eq(taggings_data)
      expect(result[:included].length).to eq(2)
    end

    it "accepts string ID" do
      expect(client).to receive(:get).with("/api/v2/signups/789?include=taggings", params: {})
      people.taggings("789")
    end
  end

  describe "#rsvps" do
    it "makes GET request to /api/v2/event_rsvps with filter parameter" do
      expected_query = "filter%5Bperson_id%5D=123&include=event"
      expect(client).to receive(:get)
        .with("/api/v2/event_rsvps?#{expected_query}", params: {})

      people.rsvps(123)
    end

    it "includes event by default" do
      expected_query = "filter%5Bperson_id%5D=123&include=event"
      expect(client).to receive(:get)
        .with("/api/v2/event_rsvps?#{expected_query}", params: {})

      people.rsvps(123)
    end

    it "excludes event when include_event is false" do
      expected_query = "filter%5Bperson_id%5D=123"
      expect(client).to receive(:get)
        .with("/api/v2/event_rsvps?#{expected_query}", params: {})

      people.rsvps(123, include_event: false)
    end

    it "returns JSON:API formatted data" do
      rsvp_data = {
        data: [
          {
            type: "event_rsvp",
            id: "1",
            attributes: {status: "yes"},
            relationships: {
              event: {data: {type: "event", id: "100"}}
            }
          }
        ],
        included: [
          {
            type: "event",
            id: "100",
            attributes: {
              name: "Town Hall",
              starts_at: "2025-01-15T18:00:00Z"
            }
          }
        ]
      }

      allow(client).to receive(:get).and_return(rsvp_data)
      result = people.rsvps(123)

      expect(result).to eq(rsvp_data)
      expect(result[:data].length).to eq(1)
      expect(result[:included].length).to eq(1)
    end

    it "accepts string ID" do
      expected_query = "filter%5Bperson_id%5D=456&include=event"
      expect(client).to receive(:get)
        .with("/api/v2/event_rsvps?#{expected_query}", params: {})

      people.rsvps("456")
    end
  end

  describe "#activities" do
    it "makes GET request to /api/v1/people/:id/activities" do
      expect(client).to receive(:get).with("/api/v1/people/123/activities", params: {})
      people.activities(123)
    end

    it "returns activities data with results array" do
      activities_data = {
        results: [
          {type: "email_sent", created_at: "2024-12-01T10:00:00Z"},
          {type: "page_view", created_at: "2024-12-02T14:30:00Z"}
        ]
      }

      allow(client).to receive(:get).and_return(activities_data)
      result = people.activities(123)

      expect(result).to eq(activities_data)
      expect(result[:results].length).to eq(2)
    end

    it "accepts string ID" do
      expect(client).to receive(:get).with("/api/v1/people/999/activities", params: {})
      people.activities("999")
    end

    it "raises NotFoundError if endpoint is not available" do
      allow(client).to receive(:get)
        .and_raise(NationbuilderApi::NotFoundError, "Endpoint not found")

      expect {
        people.activities(123)
      }.to raise_error(NationbuilderApi::NotFoundError)
    end
  end

  describe "#update" do
    let(:update_attributes) do
      {
        first_name: "John",
        last_name: "Doe",
        email: "john@example.com",
        mobile: "+1234567890"
      }
    end

    let(:expected_body) do
      {
        data: {
          type: "signups",
          id: "123",
          attributes: update_attributes
        }
      }
    end

    it "makes PATCH request to /api/v2/signups/:id" do
      expect(client).to receive(:patch)
        .with("/api/v2/signups/123", body: expected_body)

      people.update(123, attributes: update_attributes)
    end

    it "returns updated person data in JSON:API format" do
      updated_person = {
        data: {
          type: "signup",
          id: "123",
          attributes: {
            first_name: "John",
            last_name: "Doe",
            email: "john@example.com",
            mobile: "+1234567890"
          }
        }
      }

      allow(client).to receive(:patch).and_return(updated_person)
      result = people.update(123, attributes: update_attributes)

      expect(result).to eq(updated_person)
      expect(result[:data][:attributes][:first_name]).to eq("John")
    end

    it "accepts string ID" do
      expected_body_with_string_id = {
        data: {
          type: "signups",
          id: "456",
          attributes: update_attributes
        }
      }

      expect(client).to receive(:patch)
        .with("/api/v2/signups/456", body: expected_body_with_string_id)

      people.update("456", attributes: update_attributes)
    end

    it "handles nested address attributes" do
      address_attributes = {
        primary_address: {
          address1: "123 Main St",
          city: "Portland",
          state: "OR",
          zip: "97201",
          country_code: "US"
        }
      }

      expected_address_body = {
        data: {
          type: "signups",
          id: "123",
          attributes: address_attributes
        }
      }

      expect(client).to receive(:patch)
        .with("/api/v2/signups/123", body: expected_address_body)

      people.update(123, attributes: address_attributes)
    end

    it "handles empty attributes hash" do
      empty_body = {
        data: {
          type: "signups",
          id: "123",
          attributes: {}
        }
      }

      expect(client).to receive(:patch)
        .with("/api/v2/signups/123", body: empty_body)

      people.update(123, attributes: {})
    end

    it "sets type field to 'signups' in request body" do
      expect(client).to receive(:patch) do |_path, options|
        expect(options[:body][:data][:type]).to eq("signups")
      end

      people.update(123, attributes: update_attributes)
    end

    it "raises NotFoundError when person does not exist" do
      allow(client).to receive(:patch)
        .and_raise(NationbuilderApi::NotFoundError, "Person not found")

      expect {
        people.update(999, attributes: update_attributes)
      }.to raise_error(NationbuilderApi::NotFoundError, "Person not found")
    end

    it "raises ValidationError for invalid attributes" do
      allow(client).to receive(:patch)
        .and_raise(NationbuilderApi::ValidationError, "Invalid email format")

      expect {
        people.update(123, attributes: {email: "invalid-email"})
      }.to raise_error(NationbuilderApi::ValidationError, "Invalid email format")
    end

    it "raises AuthenticationError when token is invalid" do
      allow(client).to receive(:patch)
        .and_raise(NationbuilderApi::AuthenticationError, "Token expired")

      expect {
        people.update(123, attributes: update_attributes)
      }.to raise_error(NationbuilderApi::AuthenticationError, "Token expired")
    end
  end

  describe "query string building" do
    it "properly encodes nested filter parameters" do
      # Test the query string building by checking the actual call
      expected_query = "filter%5Bperson_id%5D=123&include=event"
      expect(client).to receive(:get)
        .with("/api/v2/event_rsvps?#{expected_query}", params: {})

      people.rsvps(123)
    end

    it "handles string IDs in filters" do
      expected_query = "filter%5Bperson_id%5D=abc123&include=event"
      expect(client).to receive(:get)
        .with("/api/v2/event_rsvps?#{expected_query}", params: {})

      people.rsvps("abc123")
    end
  end

  describe "#list_taggings" do
    it "makes GET request to /api/v1/people/:id/taggings" do
      expect(client).to receive(:get).with("/api/v1/people/123/taggings", params: {})
      people.list_taggings(123)
    end

    it "returns taggings data with tag names in V1 format" do
      taggings_data = {
        taggings: [
          {tag: "volunteer", person_id: 123},
          {tag: "donor", person_id: 123}
        ]
      }

      allow(client).to receive(:get).and_return(taggings_data)
      result = people.list_taggings(123)

      expect(result).to eq(taggings_data)
      expect(result[:taggings].length).to eq(2)
      expect(result[:taggings].first[:tag]).to eq("volunteer")
    end

    it "accepts string ID" do
      expect(client).to receive(:get).with("/api/v1/people/456/taggings", params: {})
      people.list_taggings("456")
    end
  end

  describe "#add_tagging" do
    it "makes PUT request to /api/v1/people/:id/taggings" do
      expected_body = {tagging: {tag: "volunteer"}}
      expect(client).to receive(:put)
        .with("/api/v1/people/123/taggings", body: expected_body)

      people.add_tagging(123, "volunteer")
    end

    it "accepts string ID" do
      expected_body = {tagging: {tag: "donor"}}
      expect(client).to receive(:put)
        .with("/api/v1/people/456/taggings", body: expected_body)

      people.add_tagging("456", "donor")
    end

    it "returns response from API" do
      response_data = {
        tagging: {tag: "volunteer", person_id: 123}
      }

      allow(client).to receive(:put).and_return(response_data)
      result = people.add_tagging(123, "volunteer")

      expect(result).to eq(response_data)
    end
  end

  describe "#remove_tagging" do
    it "makes DELETE request to /api/v1/people/:id/taggings/:tag" do
      expect(client).to receive(:delete)
        .with("/api/v1/people/123/taggings/volunteer")

      people.remove_tagging(123, "volunteer")
    end

    it "accepts string ID" do
      expect(client).to receive(:delete)
        .with("/api/v1/people/456/taggings/donor")

      people.remove_tagging("456", "donor")
    end

    it "URL encodes tag name with spaces" do
      expect(client).to receive(:delete)
        .with("/api/v1/people/123/taggings/needs follow-up")

      people.remove_tagging(123, "needs follow-up")
    end

    it "returns response from API" do
      response_data = {status: "deleted"}

      allow(client).to receive(:delete).and_return(response_data)
      result = people.remove_tagging(123, "volunteer")

      expect(result).to eq(response_data)
    end
  end
end
