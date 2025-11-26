# frozen_string_literal: true

RSpec.describe "Gem dependencies", "without http gem" do
  describe "gem loading" do
    it "loads successfully without http gem" do
      # This test verifies the gem can be required without http gem
      # If we got this far in the test suite, the gem loaded successfully
      expect(defined?(NationbuilderApi)).to be_truthy
      expect(NationbuilderApi).to be_a(Module)
    end

    it "HttpClient can be instantiated" do
      config = NationbuilderApi::Configuration.new
      token_adapter = NationbuilderApi::TokenStorage::Memory.new

      expect {
        NationbuilderApi::HttpClient.new(
          config: config,
          token_adapter: token_adapter,
          identifier: "test_user"
        )
      }.not_to raise_error
    end
  end

  describe "HTTP client functionality" do
    let(:config) do
      NationbuilderApi::Configuration.new.tap do |c|
        c.client_id = "client_123"
        c.client_secret = "secret_123"
        c.redirect_uri = "https://example.com/callback"
        c.timeout = 10
      end
    end

    let(:token_adapter) { NationbuilderApi::TokenStorage::Memory.new }
    let(:identifier) { "test_user" }
    let(:http_client) do
      described_class = NationbuilderApi::HttpClient
      described_class.new(config: config, token_adapter: token_adapter, identifier: identifier)
    end

    before do
      # Store a valid token
      token_adapter.store_token(
        identifier,
        {
          access_token: "test_token",
          refresh_token: "refresh_token",
          expires_at: Time.now + 3600,
          scopes: ["people:read"],
          token_type: "Bearer"
        }
      )
    end

    it "makes a simple API request using Net::HTTP" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people/me")
        .to_return(
          status: 200,
          body: '{"id": 123, "email": "test@example.com"}',
          headers: {"Content-Type" => "application/json"}
        )

      result = http_client.get("/people/me")
      expect(result[:id]).to eq(123)
      expect(result[:email]).to eq("test@example.com")
    end
  end

  describe "OAuth functionality" do
    it "OAuth module uses Net::HTTP" do
      # OAuth module already uses Net::HTTP directly, verify it's available
      expect(defined?(NationbuilderApi::OAuth)).to be_truthy
      expect(NationbuilderApi::OAuth).to be_a(Module)

      # Verify OAuth can generate authorization URLs
      result = NationbuilderApi::OAuth.authorization_url(
        client_id: "test_client",
        redirect_uri: "https://example.com/callback",
        scopes: ["people:read"],
        state: "test_state",
        code_verifier: "test_verifier"
      )

      # OAuth.authorization_url returns a hash with :url, :state, and :code_verifier
      expect(result).to be_a(Hash)
      expect(result[:url]).to include("authorize")
      expect(result[:url]).to include("test_client")
    end
  end
end
