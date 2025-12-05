# frozen_string_literal: true

RSpec.describe NationbuilderApi::Resources::People do
  let(:client) do
    instance_double(
      NationbuilderApi::Client,
      get: nil,
      post: nil,
      patch: nil,
      delete: nil
    )
  end

  subject(:people) { described_class.new(client) }

  describe "#show" do
    it "makes GET request to /api/v1/people/:id" do
      expect(client).to receive(:get).with("/api/v1/people/123", params: {})
      people.show(123)
    end

    it "returns person data" do
      person_data = {
        person: {
          id: 123,
          first_name: "John",
          last_name: "Doe",
          email: "john@example.com"
        }
      }

      allow(client).to receive(:get).and_return(person_data)
      result = people.show(123)

      expect(result).to eq(person_data)
    end

    it "accepts string ID" do
      expect(client).to receive(:get).with("/api/v1/people/456", params: {})
      people.show("456")
    end
  end

  describe "#taggings" do
    it "makes GET request to /api/v1/people/:id/taggings" do
      expect(client).to receive(:get).with("/api/v1/people/123/taggings", params: {})
      people.taggings(123)
    end

    it "returns taggings data with results array" do
      taggings_data = {
        results: [
          {tag: "volunteer", created_at: "2024-01-01"},
          {tag: "donor", created_at: "2024-01-02"}
        ]
      }

      allow(client).to receive(:get).and_return(taggings_data)
      result = people.taggings(123)

      expect(result).to eq(taggings_data)
      expect(result[:results].length).to eq(2)
    end

    it "accepts string ID" do
      expect(client).to receive(:get).with("/api/v1/people/789/taggings", params: {})
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
end
