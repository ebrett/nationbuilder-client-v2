# frozen_string_literal: true

RSpec.describe NationbuilderApi::Resources::Donations do
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
      config: config
    )
  end

  subject(:donations) { described_class.new(client) }

  describe "#list" do
    it "makes GET request to /api/v2/donations" do
      expect(client).to receive(:get).with("/api/v2/donations", params: {})
      donations.list
    end

    it "returns list of donations in JSON:API format" do
      list_data = {
        data: [
          {type: "donation", id: "1", attributes: {amount_in_cents: 5000}},
          {type: "donation", id: "2", attributes: {amount_in_cents: 10000}}
        ]
      }

      allow(client).to receive(:get).and_return(list_data)
      result = donations.list

      expect(result).to eq(list_data)
      expect(result[:data].length).to eq(2)
    end

    it "supports pagination parameters" do
      expected_params = {page: {number: 2, size: 50}}
      expect(client).to receive(:get).with("/api/v2/donations", params: expected_params)

      donations.list(page: 2, per_page: 50)
    end

    it "supports filtering parameters" do
      expected_params = {filter: {donor_id: "123"}}
      expect(client).to receive(:get).with("/api/v2/donations", params: expected_params)

      donations.list(filter: {donor_id: "123"})
    end
  end

  describe "#show" do
    it "makes GET request to /api/v2/donations/:id" do
      expect(client).to receive(:get).with("/api/v2/donations/123", params: {})
      donations.show(123)
    end

    it "returns donation data in JSON:API format" do
      donation_data = {
        data: {
          type: "donation",
          id: "123",
          attributes: {
            amount_in_cents: 5000,
            donated_at: "2025-01-15T10:00:00Z"
          }
        }
      }

      allow(client).to receive(:get).and_return(donation_data)
      result = donations.show(123)

      expect(result).to eq(donation_data)
    end

    it "accepts string ID" do
      expect(client).to receive(:get).with("/api/v2/donations/456", params: {})
      donations.show("456")
    end
  end

  describe "#create" do
    let(:donation_attributes) do
      {
        amount_in_cents: 5000,
        donor_id: "123",
        donated_at: "2025-01-15T10:00:00Z"
      }
    end

    let(:expected_body) do
      {
        data: {
          type: "donations",
          attributes: donation_attributes
        }
      }
    end

    it "makes POST request to /api/v2/donations" do
      expect(client).to receive(:post)
        .with("/api/v2/donations", body: expected_body)

      donations.create(attributes: donation_attributes)
    end

    it "returns created donation in JSON:API format" do
      created_donation = {
        data: {
          type: "donation",
          id: "123",
          attributes: donation_attributes
        }
      }

      allow(client).to receive(:post).and_return(created_donation)
      result = donations.create(attributes: donation_attributes)

      expect(result).to eq(created_donation)
      expect(result.dig(:data, :id)).to eq("123")
    end

    it "raises ValidationError for invalid attributes" do
      allow(client).to receive(:post)
        .and_raise(NationbuilderApi::ValidationError, "Invalid amount")

      expect {
        donations.create(attributes: {amount_in_cents: -100})
      }.to raise_error(NationbuilderApi::ValidationError, "Invalid amount")
    end
  end

  describe "#update" do
    let(:update_attributes) do
      {
        amount_in_cents: 7500,
        note: "Updated donation amount"
      }
    end

    let(:expected_body) do
      {
        data: {
          type: "donations",
          id: "123",
          attributes: update_attributes
        }
      }
    end

    it "makes PATCH request to /api/v2/donations/:id" do
      expect(client).to receive(:patch)
        .with("/api/v2/donations/123", body: expected_body)

      donations.update(123, attributes: update_attributes)
    end

    it "returns updated donation in JSON:API format" do
      updated_donation = {
        data: {
          type: "donation",
          id: "123",
          attributes: update_attributes
        }
      }

      allow(client).to receive(:patch).and_return(updated_donation)
      result = donations.update(123, attributes: update_attributes)

      expect(result).to eq(updated_donation)
    end

    it "accepts string ID" do
      expected_body_with_string = {
        data: {
          type: "donations",
          id: "456",
          attributes: update_attributes
        }
      }

      expect(client).to receive(:patch)
        .with("/api/v2/donations/456", body: expected_body_with_string)

      donations.update("456", attributes: update_attributes)
    end

    it "raises NotFoundError when donation not found" do
      allow(client).to receive(:patch)
        .and_raise(NationbuilderApi::NotFoundError, "Donation not found")

      expect {
        donations.update(999, attributes: update_attributes)
      }.to raise_error(NationbuilderApi::NotFoundError, "Donation not found")
    end
  end
end
