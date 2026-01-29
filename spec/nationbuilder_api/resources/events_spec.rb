# frozen_string_literal: true

RSpec.describe NationbuilderApi::Resources::Events do
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

  subject(:events) { described_class.new(client) }

  describe "#list" do
    it "makes GET request to /api/v2/events" do
      expect(client).to receive(:get).with("/api/v2/events", params: {})
      events.list
    end

    it "returns list of events in JSON:API format" do
      list_data = {
        data: [
          {type: "event", id: "1", attributes: {name: "Fundraiser", start_time: "2025-02-01T18:00:00Z"}},
          {type: "event", id: "2", attributes: {name: "Rally", start_time: "2025-02-15T14:00:00Z"}}
        ]
      }

      allow(client).to receive(:get).and_return(list_data)
      result = events.list

      expect(result).to eq(list_data)
      expect(result[:data].length).to eq(2)
    end

    it "supports pagination parameters" do
      expected_params = {page: {number: 2, size: 50}}
      expect(client).to receive(:get).with("/api/v2/events", params: expected_params)

      events.list(page: 2, per_page: 50)
    end

    it "supports filtering parameters" do
      expected_params = {filter: {status: "published"}}
      expect(client).to receive(:get).with("/api/v2/events", params: expected_params)

      events.list(filter: {status: "published"})
    end
  end

  describe "#show" do
    it "makes GET request to /api/v2/events/:id" do
      expect(client).to receive(:get).with("/api/v2/events/123", params: {})
      events.show(123)
    end

    it "returns event data in JSON:API format" do
      event_data = {
        data: {
          type: "event",
          id: "123",
          attributes: {
            name: "Fundraising Gala",
            start_time: "2025-02-01T18:00:00Z",
            end_time: "2025-02-01T22:00:00Z",
            status: "published"
          }
        }
      }

      allow(client).to receive(:get).and_return(event_data)
      result = events.show(123)

      expect(result).to eq(event_data)
    end

    it "accepts string ID" do
      expect(client).to receive(:get).with("/api/v2/events/456", params: {})
      events.show("456")
    end

    it "supports including RSVPs" do
      expect(client).to receive(:get).with("/api/v2/events/123?include=rsvps", params: {})
      events.show(123, include_rsvps: true)
    end
  end

  describe "#create" do
    let(:event_attributes) do
      {
        name: "Fundraising Gala",
        start_time: "2025-02-01T18:00:00Z",
        end_time: "2025-02-01T22:00:00Z",
        status: "published"
      }
    end

    let(:expected_body) do
      {
        data: {
          type: "events",
          attributes: event_attributes
        }
      }
    end

    it "makes POST request to /api/v2/events" do
      expect(client).to receive(:post)
        .with("/api/v2/events", body: expected_body)

      events.create(attributes: event_attributes)
    end

    it "returns created event in JSON:API format" do
      created_event = {
        data: {
          type: "event",
          id: "123",
          attributes: event_attributes
        }
      }

      allow(client).to receive(:post).and_return(created_event)
      result = events.create(attributes: event_attributes)

      expect(result).to eq(created_event)
      expect(result.dig(:data, :id)).to eq("123")
    end

    it "raises ValidationError for invalid attributes" do
      allow(client).to receive(:post)
        .and_raise(NationbuilderApi::ValidationError, "Invalid event name")

      expect {
        events.create(attributes: {name: ""})
      }.to raise_error(NationbuilderApi::ValidationError, "Invalid event name")
    end
  end

  describe "#update" do
    let(:update_attributes) do
      {
        name: "Updated Event Name",
        status: "published"
      }
    end

    let(:expected_body) do
      {
        data: {
          type: "events",
          id: "123",
          attributes: update_attributes
        }
      }
    end

    it "makes PATCH request to /api/v2/events/:id" do
      expect(client).to receive(:patch)
        .with("/api/v2/events/123", body: expected_body)

      events.update(123, attributes: update_attributes)
    end

    it "returns updated event in JSON:API format" do
      updated_event = {
        data: {
          type: "event",
          id: "123",
          attributes: update_attributes
        }
      }

      allow(client).to receive(:patch).and_return(updated_event)
      result = events.update(123, attributes: update_attributes)

      expect(result).to eq(updated_event)
    end

    it "accepts string ID" do
      expected_body_with_string = {
        data: {
          type: "events",
          id: "456",
          attributes: update_attributes
        }
      }

      expect(client).to receive(:patch)
        .with("/api/v2/events/456", body: expected_body_with_string)

      events.update("456", attributes: update_attributes)
    end

    it "raises NotFoundError when event not found" do
      allow(client).to receive(:patch)
        .and_raise(NationbuilderApi::NotFoundError, "Event not found")

      expect {
        events.update(999, attributes: update_attributes)
      }.to raise_error(NationbuilderApi::NotFoundError, "Event not found")
    end
  end

  describe "#delete" do
    it "makes DELETE request to /api/v2/events/:id" do
      expect(client).to receive(:delete).with("/api/v2/events/123")
      events.delete(123)
    end

    it "accepts string ID" do
      expect(client).to receive(:delete).with("/api/v2/events/456")
      events.delete("456")
    end

    it "returns response from API" do
      response = {success: true}
      allow(client).to receive(:delete).and_return(response)
      result = events.delete(123)

      expect(result).to eq(response)
    end

    it "raises NotFoundError when event not found" do
      allow(client).to receive(:delete)
        .and_raise(NationbuilderApi::NotFoundError, "Event not found")

      expect {
        events.delete(999)
      }.to raise_error(NationbuilderApi::NotFoundError, "Event not found")
    end
  end

  describe "#rsvps" do
    it "makes GET request to /api/v2/event_rsvps with event_id filter" do
      expect(client).to receive(:get).with("/api/v2/event_rsvps?filter[event_id]=123", params: {})
      events.rsvps(123)
    end

    it "returns RSVP data in JSON:API format" do
      rsvp_data = {
        data: [
          {type: "event_rsvp", id: "1", attributes: {status: "accepted"}},
          {type: "event_rsvp", id: "2", attributes: {status: "declined"}}
        ]
      }

      allow(client).to receive(:get).and_return(rsvp_data)
      result = events.rsvps(123)

      expect(result).to eq(rsvp_data)
    end

    it "accepts string ID" do
      expect(client).to receive(:get).with("/api/v2/event_rsvps?filter[event_id]=456", params: {})
      events.rsvps("456")
    end

    it "supports including person data" do
      expect(client).to receive(:get).with("/api/v2/event_rsvps?filter[event_id]=123&include=person", params: {})
      events.rsvps(123, include_person: true)
    end
  end

  describe "#create_rsvp" do
    let(:rsvp_attributes) do
      {
        person_id: "789",
        status: "accepted",
        guests_count: 2
      }
    end

    let(:expected_body) do
      {
        data: {
          type: "event_rsvps",
          attributes: rsvp_attributes.merge(event_id: "123")
        }
      }
    end

    it "makes POST request to /api/v2/event_rsvps" do
      expect(client).to receive(:post)
        .with("/api/v2/event_rsvps", body: expected_body)

      events.create_rsvp(123, attributes: rsvp_attributes)
    end

    it "returns created RSVP in JSON:API format" do
      created_rsvp = {
        data: {
          type: "event_rsvp",
          id: "999",
          attributes: rsvp_attributes.merge(event_id: "123")
        }
      }

      allow(client).to receive(:post).and_return(created_rsvp)
      result = events.create_rsvp(123, attributes: rsvp_attributes)

      expect(result).to eq(created_rsvp)
    end

    it "accepts string event ID" do
      expected_body_with_string = {
        data: {
          type: "event_rsvps",
          attributes: rsvp_attributes.merge(event_id: "456")
        }
      }

      expect(client).to receive(:post)
        .with("/api/v2/event_rsvps", body: expected_body_with_string)

      events.create_rsvp("456", attributes: rsvp_attributes)
    end

    it "raises ValidationError for invalid RSVP" do
      allow(client).to receive(:post)
        .and_raise(NationbuilderApi::ValidationError, "Invalid person_id")

      expect {
        events.create_rsvp(123, attributes: {person_id: nil})
      }.to raise_error(NationbuilderApi::ValidationError, "Invalid person_id")
    end
  end

  describe "#update_rsvp" do
    let(:rsvp_update_attributes) do
      {
        status: "declined",
        guests_count: 0
      }
    end

    let(:expected_body) do
      {
        data: {
          type: "event_rsvps",
          id: "999",
          attributes: rsvp_update_attributes
        }
      }
    end

    it "makes PATCH request to /api/v2/event_rsvps/:rsvp_id" do
      expect(client).to receive(:patch)
        .with("/api/v2/event_rsvps/999", body: expected_body)

      events.update_rsvp(999, attributes: rsvp_update_attributes)
    end

    it "returns updated RSVP in JSON:API format" do
      updated_rsvp = {
        data: {
          type: "event_rsvp",
          id: "999",
          attributes: rsvp_update_attributes
        }
      }

      allow(client).to receive(:patch).and_return(updated_rsvp)
      result = events.update_rsvp(999, attributes: rsvp_update_attributes)

      expect(result).to eq(updated_rsvp)
    end

    it "accepts string RSVP ID" do
      expected_body_with_string = {
        data: {
          type: "event_rsvps",
          id: "888",
          attributes: rsvp_update_attributes
        }
      }

      expect(client).to receive(:patch)
        .with("/api/v2/event_rsvps/888", body: expected_body_with_string)

      events.update_rsvp("888", attributes: rsvp_update_attributes)
    end

    it "raises NotFoundError when RSVP not found" do
      allow(client).to receive(:patch)
        .and_raise(NationbuilderApi::NotFoundError, "RSVP not found")

      expect {
        events.update_rsvp(999, attributes: rsvp_update_attributes)
      }.to raise_error(NationbuilderApi::NotFoundError, "RSVP not found")
    end
  end

  describe "#delete_rsvp" do
    it "makes DELETE request to /api/v2/event_rsvps/:rsvp_id" do
      expect(client).to receive(:delete).with("/api/v2/event_rsvps/999")
      events.delete_rsvp(999)
    end

    it "accepts string RSVP ID" do
      expect(client).to receive(:delete).with("/api/v2/event_rsvps/888")
      events.delete_rsvp("888")
    end

    it "returns response from API" do
      response = {success: true}
      allow(client).to receive(:delete).and_return(response)
      result = events.delete_rsvp(999)

      expect(result).to eq(response)
    end

    it "raises NotFoundError when RSVP not found" do
      allow(client).to receive(:delete)
        .and_raise(NationbuilderApi::NotFoundError, "RSVP not found")

      expect {
        events.delete_rsvp(999)
      }.to raise_error(NationbuilderApi::NotFoundError, "RSVP not found")
    end
  end
end
