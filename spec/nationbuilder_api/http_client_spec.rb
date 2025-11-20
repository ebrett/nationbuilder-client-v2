# frozen_string_literal: true

RSpec.describe NationbuilderApi::HttpClient do
  let(:config) do
    NationbuilderApi::Configuration.new.tap do |c|
      c.client_id = "client_123"
      c.client_secret = "secret_123"
      c.redirect_uri = "https://example.com/callback"
      c.timeout = 30
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

  describe "#get" do
    it "makes GET request with query parameters" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people?page=1")
        .to_return(status: 200, body: '{"data": []}', headers: {"Content-Type" => "application/json"})

      result = http_client.get("/people", params: {page: 1})
      expect(result[:data]).to eq([])
    end
  end

  describe "#patch" do
    it "makes PATCH request" do
      stub_request(:patch, "https://api.nationbuilder.com/v2/people/123")
        .to_return(status: 200, body: '{"id": 123}', headers: {"Content-Type" => "application/json"})

      result = http_client.patch("/people/123", body: {first_name: "Jane"})
      expect(result[:id]).to eq(123)
    end
  end

  describe "#put" do
    it "makes PUT request" do
      stub_request(:put, "https://api.nationbuilder.com/v2/people/123")
        .to_return(status: 200, body: '{"id": 123}', headers: {"Content-Type" => "application/json"})

      result = http_client.put("/people/123", body: {first_name: "Jane"})
      expect(result[:id]).to eq(123)
    end
  end

  describe "#delete" do
    it "makes DELETE request" do
      stub_request(:delete, "https://api.nationbuilder.com/v2/people/123")
        .to_return(status: 204, body: "", headers: {})

      result = http_client.delete("/people/123")
      expect(result).to be_nil
    end
  end

  describe "error handling" do
    it "raises ValidationError on 422" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(status: 422, body: '{"error": "validation_error"}', headers: {"Content-Type" => "application/json"})

      expect {
        http_client.get("/people")
      }.to raise_error(NationbuilderApi::ValidationError)
    end

    it "raises AuthorizationError on 403" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(status: 403, body: '{"error": "forbidden"}', headers: {"Content-Type" => "application/json"})

      expect {
        http_client.get("/people")
      }.to raise_error(NationbuilderApi::AuthorizationError)
    end

    it "raises NetworkError on timeout" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_timeout

      expect {
        http_client.get("/people")
      }.to raise_error(NationbuilderApi::NetworkError)
    end

    it "handles non-JSON response body" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(status: 200, body: "Plain text", headers: {})

      result = http_client.get("/people")
      expect(result).to eq("Plain text")
    end
  end

  describe "URL building" do
    it "handles paths with leading slash" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(status: 200, body: "{}", headers: {"Content-Type" => "application/json"})

      http_client.get("/people")
      expect(WebMock).to have_requested(:get, "https://api.nationbuilder.com/v2/people")
    end

    it "handles paths without leading slash" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(status: 200, body: "{}", headers: {"Content-Type" => "application/json"})

      http_client.get("people")
      expect(WebMock).to have_requested(:get, "https://api.nationbuilder.com/v2/people")
    end

    it "handles base URL with trailing slash" do
      config.base_url = "https://api.nationbuilder.com/v2/"

      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(status: 200, body: "{}", headers: {"Content-Type" => "application/json"})

      http_client.get("/people")
      expect(WebMock).to have_requested(:get, "https://api.nationbuilder.com/v2/people")
    end
  end

  describe "User-Agent header" do
    it "includes gem version and Ruby version" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .with(headers: {"User-Agent" => /NationbuilderApi\/#{NationbuilderApi::VERSION} Ruby\/#{RUBY_VERSION}/o})
        .to_return(status: 200, body: "{}", headers: {"Content-Type" => "application/json"})

      http_client.get("/people")
    end
  end
end
