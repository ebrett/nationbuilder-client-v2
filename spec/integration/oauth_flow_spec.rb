# frozen_string_literal: true

RSpec.describe "OAuth Flow Integration" do
  let(:client) do
    NationbuilderApi::Client.new(
      client_id: "test_client_id",
      client_secret: "test_client_secret",
      redirect_uri: "https://example.com/callback"
    )
  end

  describe "complete OAuth flow" do
    it "generates authorization URL, exchanges code, and makes API call" do
      # Step 1: Generate authorization URL
      auth_result = client.authorize_url(scopes: [NationbuilderApi::SCOPE_PEOPLE_READ])
      expect(auth_result[:url]).to include("client_id=test_client_id")
      expect(auth_result[:code_verifier]).to be_a(String)

      # Step 2: Exchange authorization code for token
      token_response = {
        access_token: "access_token_abc123",
        refresh_token: "refresh_token_xyz789",
        expires_in: 7200,
        token_type: "Bearer",
        scope: "people:read"
      }.to_json

      stub_request(:post, "https://nationbuilder.com/oauth/token")
        .with(body: hash_including("code" => "auth_code_from_callback"))
        .to_return(status: 200, body: token_response, headers: {"Content-Type" => "application/json"})

      token_data = client.exchange_code_for_token(
        code: "auth_code_from_callback",
        code_verifier: auth_result[:code_verifier]
      )

      expect(token_data[:access_token]).to eq("access_token_abc123")
      expect(token_data[:refresh_token]).to eq("refresh_token_xyz789")

      # Step 3: Make authenticated API call
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .with(headers: {"Authorization" => "Bearer access_token_abc123"})
        .to_return(status: 200, body: '{"data": [{"id": 1, "first_name": "John"}]}', headers: {"Content-Type" => "application/json"})

      people = client.get("/people")
      expect(people[:data].first[:first_name]).to eq("John")
    end
  end

  describe "automatic token refresh" do
    it "refreshes expired token before API call" do
      # Store an expired token
      client.token_adapter.store_token(
        client.identifier,
        {
          access_token: "expired_token",
          refresh_token: "refresh_token_123",
          expires_at: Time.now - 3600, # Expired 1 hour ago
          scopes: ["people:read"],
          token_type: "Bearer"
        }
      )

      # Mock token refresh
      refresh_response = {
        access_token: "fresh_access_token",
        refresh_token: "new_refresh_token",
        expires_in: 7200,
        token_type: "Bearer",
        scope: "people:read"
      }.to_json

      stub_request(:post, "https://nationbuilder.com/oauth/token")
        .with(body: hash_including("grant_type" => "refresh_token"))
        .to_return(status: 200, body: refresh_response, headers: {"Content-Type" => "application/json"})

      # Mock API call with fresh token
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .with(headers: {"Authorization" => "Bearer fresh_access_token"})
        .to_return(status: 200, body: '{"data": []}', headers: {"Content-Type" => "application/json"})

      # API call should trigger automatic refresh
      result = client.get("/people")
      expect(result[:data]).to eq([])

      # Verify token was refreshed
      stored = client.token_adapter.retrieve_token(client.identifier)
      expect(stored[:access_token]).to eq("fresh_access_token")
    end
  end

  describe "error handling" do
    before do
      # Store a valid token for error tests
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

    it "raises AuthenticationError on 401" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(status: 401, body: '{"error": "unauthorized"}', headers: {"Content-Type" => "application/json"})

      expect {
        client.get("/people")
      }.to raise_error(NationbuilderApi::AuthenticationError)
    end

    it "raises NotFoundError on 404" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people/999")
        .to_return(status: 404, body: '{"error": "not_found"}', headers: {"Content-Type" => "application/json"})

      expect {
        client.get("/people/999")
      }.to raise_error(NationbuilderApi::NotFoundError)
    end

    it "raises RateLimitError on 429" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(
          status: 429,
          body: '{"error": "rate_limit_exceeded"}',
          headers: {"Content-Type" => "application/json", "Retry-After" => "120"}
        )

      expect {
        client.get("/people")
      }.to raise_error(NationbuilderApi::RateLimitError) do |error|
        expect(error.retryable?).to be true
        expect(error.retry_after).to be_within(2).of(Time.now + 120)
      end
    end

    it "raises ServerError on 500" do
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .to_return(status: 500, body: "Internal Server Error")

      expect {
        client.get("/people")
      }.to raise_error(NationbuilderApi::ServerError) do |error|
        expect(error.retryable?).to be true
      end
    end
  end

  describe "multi-tenant usage" do
    it "supports multiple token identifiers" do
      client1 = NationbuilderApi::Client.new(
        client_id: "client_id",
        client_secret: "client_secret",
        redirect_uri: "https://example.com/callback",
        identifier: "account_1"
      )

      client2 = NationbuilderApi::Client.new(
        client_id: "client_id",
        client_secret: "client_secret",
        redirect_uri: "https://example.com/callback",
        identifier: "account_2"
      )

      # Store different tokens for each account
      client1.token_adapter.store_token(
        "account_1",
        {
          access_token: "token_account_1",
          refresh_token: "refresh_1",
          expires_at: Time.now + 3600,
          scopes: ["people:read"],
          token_type: "Bearer"
        }
      )

      client2.token_adapter.store_token(
        "account_2",
        {
          access_token: "token_account_2",
          refresh_token: "refresh_2",
          expires_at: Time.now + 3600,
          scopes: ["people:read"],
          token_type: "Bearer"
        }
      )

      # Verify separate tokens
      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .with(headers: {"Authorization" => "Bearer token_account_1"})
        .to_return(status: 200, body: '{"account": 1}', headers: {"Content-Type" => "application/json"})

      stub_request(:get, "https://api.nationbuilder.com/v2/people")
        .with(headers: {"Authorization" => "Bearer token_account_2"})
        .to_return(status: 200, body: '{"account": 2}', headers: {"Content-Type" => "application/json"})

      result1 = client1.get("/people")
      result2 = client2.get("/people")

      expect(result1[:account]).to eq(1)
      expect(result2[:account]).to eq(2)
    end
  end
end
