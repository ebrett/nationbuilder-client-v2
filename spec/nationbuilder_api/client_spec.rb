# frozen_string_literal: true

RSpec.describe NationbuilderApi::Client do
  let(:valid_config) do
    {
      client_id: "client_123",
      client_secret: "secret_123",
      redirect_uri: "https://example.com/callback"
    }
  end

  describe "#initialize" do
    it "initializes with valid configuration" do
      client = described_class.new(**valid_config)
      expect(client.config.client_id).to eq("client_123")
    end

    it "validates configuration on initialization" do
      expect {
        described_class.new(client_id: "client_123")
      }.to raise_error(NationbuilderApi::ConfigurationError)
    end

    it "merges instance options over global configuration" do
      NationbuilderApi.configure do |config|
        config.client_id = "global_client"
        config.client_secret = "global_secret"
        config.redirect_uri = "https://global.example.com/callback"
      end

      client = described_class.new(client_id: "instance_client")
      expect(client.config.client_id).to eq("instance_client")
      expect(client.config.client_secret).to eq("global_secret")
    end

    it "uses memory adapter by default" do
      client = described_class.new(**valid_config)
      expect(client.token_adapter).to be_a(NationbuilderApi::TokenStorage::Memory)
    end

    it "accepts custom identifier" do
      client = described_class.new(**valid_config, identifier: "user_456")
      expect(client.identifier).to eq("user_456")
    end

    it "accepts custom adapter with valid interface" do
      custom_adapter = double("CustomAdapter")
      allow(custom_adapter).to receive(:respond_to?).with(:store_token).and_return(true)
      allow(custom_adapter).to receive(:respond_to?).with(:retrieve_token).and_return(true)
      allow(custom_adapter).to receive(:respond_to?).with(:refresh_token).and_return(true)
      allow(custom_adapter).to receive(:respond_to?).with(:delete_token).and_return(true)

      client = described_class.new(**valid_config, token_adapter: custom_adapter)
      expect(client.token_adapter).to eq(custom_adapter)
    end

    it "rejects custom adapter missing required methods" do
      invalid_adapter = double("InvalidAdapter")
      allow(invalid_adapter).to receive(:respond_to?).with(:store_token).and_return(true)
      allow(invalid_adapter).to receive(:respond_to?).with(:retrieve_token).and_return(false)
      allow(invalid_adapter).to receive(:respond_to?).with(:refresh_token).and_return(false)
      allow(invalid_adapter).to receive(:respond_to?).with(:delete_token).and_return(true)

      expect {
        described_class.new(**valid_config, token_adapter: invalid_adapter)
      }.to raise_error(NationbuilderApi::ConfigurationError, /missing required methods: retrieve_token, refresh_token/)
    end
  end

  describe "#authorize_url" do
    let(:client) { described_class.new(**valid_config) }

    it "generates authorization URL" do
      result = client.authorize_url(scopes: ["people:read"])

      expect(result[:url]).to include("https://api.nationbuilder.com/oauth/authorize")
      expect(result[:url]).to include("client_id=client_123")
      expect(result[:code_verifier]).to be_a(String)
      expect(result[:state]).to be_a(String)
    end

    it "accepts custom state parameter" do
      result = client.authorize_url(state: "custom_state")
      expect(result[:state]).to eq("custom_state")
    end
  end

  describe "#exchange_code_for_token" do
    let(:client) { described_class.new(**valid_config) }

    it "exchanges code for token and stores it" do
      token_response = {
        access_token: "access_token_123",
        refresh_token: "refresh_token_123",
        expires_in: 3600,
        token_type: "Bearer",
        scope: "people:read"
      }.to_json

      stub_request(:post, "https://api.nationbuilder.com/oauth/token")
        .to_return(status: 200, body: token_response, headers: {"Content-Type" => "application/json"})

      result = client.exchange_code_for_token(code: "auth_code", code_verifier: "verifier_123")

      expect(result[:access_token]).to eq("access_token_123")

      # Verify token is stored
      stored = client.token_adapter.retrieve_token(client.identifier)
      expect(stored[:access_token]).to eq("access_token_123")
    end
  end

  describe "#refresh_token" do
    let(:client) { described_class.new(**valid_config) }

    it "refreshes stored token" do
      # Store initial token
      client.token_adapter.store_token(
        client.identifier,
        {
          access_token: "old_token",
          refresh_token: "refresh_token_123",
          expires_at: Time.now + 3600,
          scopes: ["people:read"],
          token_type: "Bearer"
        }
      )

      token_response = {
        access_token: "new_access_token",
        refresh_token: "new_refresh_token",
        expires_in: 3600,
        token_type: "Bearer",
        scope: "people:read"
      }.to_json

      stub_request(:post, "https://api.nationbuilder.com/oauth/token")
        .to_return(status: 200, body: token_response, headers: {"Content-Type" => "application/json"})

      result = client.refresh_token

      expect(result[:access_token]).to eq("new_access_token")
    end

    it "raises error when no token found" do
      expect {
        client.refresh_token
      }.to raise_error(NationbuilderApi::AuthenticationError, /No token found/)
    end
  end

  describe "#delete_token" do
    let(:client) { described_class.new(**valid_config) }

    it "deletes stored token" do
      client.token_adapter.store_token(
        client.identifier,
        {
          access_token: "token",
          refresh_token: "refresh",
          expires_at: Time.now + 3600,
          scopes: [],
          token_type: "Bearer"
        }
      )

      client.delete_token

      expect(client.token_adapter.retrieve_token(client.identifier)).to be_nil
    end
  end

  describe "HTTP methods" do
    let(:client) { described_class.new(**valid_config) }

    before do
      # Store a valid token
      client.token_adapter.store_token(
        client.identifier,
        {
          access_token: "valid_token",
          refresh_token: "refresh_token",
          expires_at: Time.now + 3600,
          scopes: ["people:read"],
          token_type: "Bearer"
        }
      )
    end

    describe "#get" do
      it "makes GET request with authentication" do
        stub_request(:get, "https://api.nationbuilder.com/v2/people")
          .with(headers: {"Authorization" => "Bearer valid_token"})
          .to_return(status: 200, body: '{"data": []}', headers: {"Content-Type" => "application/json"})

        result = client.get("/people")
        expect(result[:data]).to eq([])
      end
    end

    describe "#post" do
      it "makes POST request with JSON body" do
        stub_request(:post, "https://api.nationbuilder.com/v2/people")
          .with(
            headers: {"Authorization" => "Bearer valid_token"},
            body: hash_including("first_name" => "John")
          )
          .to_return(status: 201, body: '{"id": 123}', headers: {"Content-Type" => "application/json"})

        result = client.post("/people", body: {first_name: "John"})
        expect(result[:id]).to eq(123)
      end
    end
  end
end
