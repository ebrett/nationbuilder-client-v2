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

  describe "rate limit header logging" do
    let(:mock_logger) { instance_double(NationbuilderApi::Logger, log_request: nil, log_response: nil) }
    let(:http_client) { described_class.new(config: config, token_adapter: token_adapter, identifier: identifier, logger: mock_logger) }

    it "logs remaining and reset when both headers present" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(
          status: 200,
          body: "{}",
          headers: {"X-RateLimit-Remaining" => "42", "X-RateLimit-Reset" => "1700000000"}
        )

      expect(mock_logger).to receive(:info).with(include("remaining=42", "reset=1700000000"))
      http_client.get("/people")
    end

    it "logs only remaining when reset header absent" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(status: 200, body: "{}", headers: {"X-RateLimit-Remaining" => "10"})

      expect(mock_logger).to receive(:info).with(include("remaining=10"))
      http_client.get("/people")
    end

    it "does not log when no rate limit headers present" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(status: 200, body: "{}", headers: {"Content-Type" => "application/json"})

      expect(mock_logger).not_to receive(:info).with(include("Rate limit"))
      http_client.get("/people")
    end

    it "does not raise on unexpected header values" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(status: 200, body: "{}", headers: {"X-RateLimit-Remaining" => ""})

      allow(mock_logger).to receive(:info)
      expect { http_client.get("/people") }.not_to raise_error
    end
  end

  describe "query parameter encoding" do
    # Regression for the nested-filter bug: URI.encode_www_form does not recurse
    # into nested hashes; NationBuilder's JSON:API requires `filter[key]=value`
    # bracket form. Without flattening, NB returns HTTP 500 for any filtered call.
    it "flattens a one-level nested filter hash into bracket form" do
      stub_request(:get, "https://api.nationbuilder.com/v2/signups")
        .with(query: {"filter[email]" => "john@example.com"})
        .to_return(status: 200, body: '{"data": []}', headers: {"Content-Type" => "application/json"})

      http_client.get("/signups", params: {filter: {email: "john@example.com"}})

      expect(WebMock).to have_requested(:get, "https://api.nationbuilder.com/v2/signups")
        .with(query: {"filter[email]" => "john@example.com"})
    end

    it "flattens deeply nested params into bracket form" do
      stub_request(:get, "https://api.nationbuilder.com/v2/signups")
        .with(query: {"a[b][c]" => "1"})
        .to_return(status: 200, body: '{"data": []}', headers: {"Content-Type" => "application/json"})

      http_client.get("/signups", params: {a: {b: {c: 1}}})

      expect(WebMock).to have_requested(:get, "https://api.nationbuilder.com/v2/signups")
        .with(query: {"a[b][c]" => "1"})
    end

    it "leaves flat (non-nested) params unchanged" do
      stub_request(:get, "https://api.nationbuilder.com/v2/signups")
        .with(query: {"page" => "2", "per_page" => "50"})
        .to_return(status: 200, body: '{"data": []}', headers: {"Content-Type" => "application/json"})

      http_client.get("/signups", params: {page: 2, per_page: 50})

      expect(WebMock).to have_requested(:get, "https://api.nationbuilder.com/v2/signups")
        .with(query: {"page" => "2", "per_page" => "50"})
    end

    it "handles mixed flat and nested params" do
      stub_request(:get, "https://api.nationbuilder.com/v2/event_rsvps")
        .with(query: {"include" => "event", "filter[person_id]" => "123"})
        .to_return(status: 200, body: '{"data": []}', headers: {"Content-Type" => "application/json"})

      http_client.get("/event_rsvps", params: {include: "event", filter: {person_id: 123}})

      expect(WebMock).to have_requested(:get, "https://api.nationbuilder.com/v2/event_rsvps")
        .with(query: {"include" => "event", "filter[person_id]" => "123"})
    end

    it "encodes JSON:API page object into bracket form" do
      stub_request(:get, "https://api.nationbuilder.com/v2/signups")
        .with(query: {"page[number]" => "2", "page[size]" => "50"})
        .to_return(status: 200, body: '{"data": []}', headers: {"Content-Type" => "application/json"})

      http_client.get("/signups", params: {page: {number: 2, size: 50}})

      expect(WebMock).to have_requested(:get, "https://api.nationbuilder.com/v2/signups")
        .with(query: {"page[number]" => "2", "page[size]" => "50"})
    end
  end
end
