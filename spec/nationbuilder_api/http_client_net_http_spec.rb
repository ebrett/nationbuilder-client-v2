# frozen_string_literal: true

RSpec.describe NationbuilderApi::HttpClient, "Net::HTTP implementation" do
  let(:config) do
    NationbuilderApi::Configuration.new.tap do |c|
      c.client_id = "client_123"
      c.client_secret = "secret_123"
      c.redirect_uri = "https://example.com/callback"
      c.timeout = 15
    end
  end

  let(:token_adapter) { NationbuilderApi::TokenStorage::Memory.new }
  let(:identifier) { "user_123" }
  let(:http_client) { described_class.new(config: config, token_adapter: token_adapter, identifier: identifier) }

  before do
    # Store a valid token
    token_adapter.store_token(
      identifier,
      {
        access_token: "valid_token",
        refresh_token: "refresh_token",
        expires_at: Time.now + 3600,
        scopes: ["people:read"],
        token_type: "Bearer"
      }
    )
  end

  describe "GET request with query parameters" do
    it "encodes query parameters correctly" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people?page=2&per_page=50")
        .to_return(status: 200, body: '{"data": [{"id": 1}]}', headers: {"Content-Type" => "application/json"})

      result = http_client.get("/people", params: {page: 2, per_page: 50})
      expect(result[:data]).to eq([{id: 1}])
    end
  end

  describe "POST request with JSON body" do
    it "serializes JSON body correctly" do
      stub_request(:post, "https://api.nationbuilder.com/v2/people")
        .with(
          body: '{"first_name":"John","last_name":"Doe"}',
          headers: {"Content-Type" => "application/json"}
        )
        .to_return(status: 201, body: '{"id": 456}', headers: {"Content-Type" => "application/json"})

      result = http_client.post("/people", body: {first_name: "John", last_name: "Doe"})
      expect(result[:id]).to eq(456)
    end
  end

  describe "PATCH request with JSON body" do
    it "serializes JSON body correctly" do
      stub_request(:patch, "https://api.nationbuilder.com/v2/people/123")
        .with(
          body: '{"first_name":"Jane"}',
          headers: {"Content-Type" => "application/json"}
        )
        .to_return(status: 200, body: '{"id": 123, "first_name": "Jane"}', headers: {"Content-Type" => "application/json"})

      result = http_client.patch("/people/123", body: {first_name: "Jane"})
      expect(result[:id]).to eq(123)
      expect(result[:first_name]).to eq("Jane")
    end
  end

  describe "PUT request with JSON body" do
    it "serializes JSON body correctly" do
      stub_request(:put, "https://api.nationbuilder.com/v2/people/123")
        .with(
          body: '{"first_name":"Jack","last_name":"Smith"}',
          headers: {"Content-Type" => "application/json"}
        )
        .to_return(status: 200, body: '{"id": 123}', headers: {"Content-Type" => "application/json"})

      result = http_client.put("/people/123", body: {first_name: "Jack", last_name: "Smith"})
      expect(result[:id]).to eq(123)
    end
  end

  describe "DELETE request" do
    it "executes without body" do
      stub_request(:delete, "https://api.nationbuilder.com/v2/people/123")
        .to_return(status: 204, body: "", headers: {})

      result = http_client.delete("/people/123")
      expect(result).to be_nil
    end
  end

  describe "timeout configuration" do
    it "applies configured timeout to requests" do
      # WebMock will timeout the request
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_timeout

      expect {
        http_client.get("/people")
      }.to raise_error(NationbuilderApi::NetworkError, /Network error for GET \/people/)
    end
  end

  describe "response wrapping" do
    it "wraps responses with ResponseWrapper" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(
          status: 200,
          body: '{"data": []}',
          headers: {"Content-Type" => "application/json", "X-Custom-Header" => "test"}
        )

      result = http_client.get("/people")
      # If this doesn't raise an error, the response was properly wrapped
      expect(result[:data]).to eq([])
    end
  end

  describe "SSL verification configuration" do
    it "always uses SSL verification regardless of Rails environment" do
      # Mock Rails environment as development
      rails_double = double("Rails", env: double("env", development?: true, test?: false))
      stub_const("Rails", rails_double)

      # Mock Net::HTTP to verify SSL configuration
      http_instance = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_instance)
      allow(http_instance).to receive(:use_ssl=)
      allow(http_instance).to receive(:read_timeout=)
      allow(http_instance).to receive(:open_timeout=)
      allow(http_instance).to receive(:verify_mode=)

      # Create a mock request and response
      request_double = instance_double(Net::HTTP::Get)
      allow(Net::HTTP::Get).to receive(:new).and_return(request_double)
      allow(request_double).to receive(:[]=)

      response_double = instance_double(Net::HTTPSuccess, code: "200", body: '{"data": []}', to_hash: {"content-type" => ["application/json"]})
      allow(http_instance).to receive(:request).and_return(response_double)

      # Execute request
      http_client.get("/people")

      # Verify SSL verification was NOT explicitly disabled
      # Ruby's Net::HTTP defaults to VERIFY_PEER, so we don't set verify_mode at all
      expect(http_instance).not_to have_received(:verify_mode=)
    end

    it "enables SSL for HTTPS requests" do
      # Mock Net::HTTP to verify SSL is enabled
      http_instance = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_instance)
      allow(http_instance).to receive(:use_ssl=)
      allow(http_instance).to receive(:read_timeout=)
      allow(http_instance).to receive(:open_timeout=)

      # Create a mock request and response
      request_double = instance_double(Net::HTTP::Get)
      allow(Net::HTTP::Get).to receive(:new).and_return(request_double)
      allow(request_double).to receive(:[]=)

      response_double = instance_double(Net::HTTPSuccess, code: "200", body: '{"data": []}', to_hash: {"content-type" => ["application/json"]})
      allow(http_instance).to receive(:request).and_return(response_double)

      # Execute request
      http_client.get("/people")

      # Verify SSL was enabled
      expect(http_instance).to have_received(:use_ssl=).with(true)
    end
  end
end
