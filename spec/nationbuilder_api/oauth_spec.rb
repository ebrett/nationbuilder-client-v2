# frozen_string_literal: true

RSpec.describe NationbuilderApi::OAuth do
  describe ".generate_code_verifier" do
    it "generates a URL-safe string" do
      verifier = described_class.generate_code_verifier
      expect(verifier).to match(/\A[A-Za-z0-9_-]+\z/)
    end

    it "generates string of correct length" do
      verifier = described_class.generate_code_verifier
      expect(verifier.length).to be_between(43, 128)
    end

    it "generates unique verifiers" do
      verifier1 = described_class.generate_code_verifier
      verifier2 = described_class.generate_code_verifier
      expect(verifier1).not_to eq(verifier2)
    end
  end

  describe ".generate_code_challenge" do
    it "generates SHA256 Base64 URL-safe encoded challenge" do
      verifier = "test_verifier_123"
      challenge = described_class.generate_code_challenge(verifier)
      expect(challenge).to be_a(String)
      expect(challenge).to match(/\A[A-Za-z0-9_-]+\z/)
    end

    it "generates consistent challenge for same verifier" do
      verifier = "test_verifier_123"
      challenge1 = described_class.generate_code_challenge(verifier)
      challenge2 = described_class.generate_code_challenge(verifier)
      expect(challenge1).to eq(challenge2)
    end
  end

  describe ".authorization_url" do
    let(:params) do
      {
        client_id: "client_123",
        redirect_uri: "https://example.com/callback",
        scopes: ["people:read", "people:write"]
      }
    end

    it "generates authorization URL with PKCE parameters" do
      result = described_class.authorization_url(**params)

      expect(result[:url]).to include("https://nationbuilder.com/oauth/authorize")
      expect(result[:url]).to include("client_id=client_123")
      expect(result[:url]).to include("redirect_uri=https")
      expect(result[:url]).to include("code_challenge=")
      expect(result[:url]).to include("code_challenge_method=S256")
      expect(result[:url]).to include("response_type=code")
    end

    it "includes scopes in URL" do
      result = described_class.authorization_url(**params)
      expect(result[:url]).to include("scope=people%3Aread+people%3Awrite")
    end

    it "includes state parameter" do
      result = described_class.authorization_url(**params, state: "custom_state")
      expect(result[:url]).to include("state=custom_state")
      expect(result[:state]).to eq("custom_state")
    end

    it "generates state if not provided" do
      result = described_class.authorization_url(**params)
      expect(result[:state]).to be_a(String)
      expect(result[:state].length).to be > 20
    end

    it "returns code_verifier" do
      result = described_class.authorization_url(**params)
      expect(result[:code_verifier]).to be_a(String)
      expect(result[:code_verifier].length).to be_between(43, 128)
    end
  end

  describe ".exchange_code_for_token" do
    let(:params) do
      {
        code: "auth_code_123",
        client_id: "client_123",
        client_secret: "secret_123",
        redirect_uri: "https://example.com/callback",
        code_verifier: "verifier_123"
      }
    end

    it "exchanges authorization code for token" do
      token_response = {
        access_token: "access_token_123",
        refresh_token: "refresh_token_123",
        expires_in: 3600,
        token_type: "Bearer",
        scope: "people:read people:write"
      }.to_json

      stub_request(:post, "https://nationbuilder.com/oauth/token")
        .with(
          body: hash_including(
            "grant_type" => "authorization_code",
            "code" => "auth_code_123",
            "code_verifier" => "verifier_123"
          )
        )
        .to_return(status: 200, body: token_response, headers: {"Content-Type" => "application/json"})

      result = described_class.exchange_code_for_token(**params)

      expect(result[:access_token]).to eq("access_token_123")
      expect(result[:refresh_token]).to eq("refresh_token_123")
      expect(result[:expires_at]).to be_a(Time)
      expect(result[:scopes]).to eq(["people:read", "people:write"])
      expect(result[:token_type]).to eq("Bearer")
    end

    it "raises AuthenticationError on invalid code" do
      error_response = {
        error: "invalid_grant",
        error_description: "Invalid authorization code"
      }.to_json

      stub_request(:post, "https://nationbuilder.com/oauth/token")
        .to_return(status: 400, body: error_response, headers: {"Content-Type" => "application/json"})

      expect {
        described_class.exchange_code_for_token(**params)
      }.to raise_error(NationbuilderApi::AuthenticationError, /Invalid authorization code/)
    end
  end

  describe ".refresh_access_token" do
    let(:params) do
      {
        refresh_token: "refresh_token_123",
        client_id: "client_123",
        client_secret: "secret_123"
      }
    end

    it "refreshes access token" do
      token_response = {
        access_token: "new_access_token",
        refresh_token: "new_refresh_token",
        expires_in: 3600,
        token_type: "Bearer",
        scope: "people:read"
      }.to_json

      stub_request(:post, "https://nationbuilder.com/oauth/token")
        .with(
          body: hash_including(
            "grant_type" => "refresh_token",
            "refresh_token" => "refresh_token_123"
          )
        )
        .to_return(status: 200, body: token_response, headers: {"Content-Type" => "application/json"})

      result = described_class.refresh_access_token(**params)

      expect(result[:access_token]).to eq("new_access_token")
      expect(result[:refresh_token]).to eq("new_refresh_token")
    end
  end

  describe ".token_expired?" do
    it "returns true for expired token" do
      expires_at = Time.now - 3600
      expect(described_class.token_expired?(expires_at)).to be true
    end

    it "returns true for token expiring within buffer" do
      expires_at = Time.now + 30
      expect(described_class.token_expired?(expires_at, buffer_seconds: 60)).to be true
    end

    it "returns false for valid token" do
      expires_at = Time.now + 3600
      expect(described_class.token_expired?(expires_at)).to be false
    end

    it "returns true for nil expires_at" do
      expect(described_class.token_expired?(nil)).to be true
    end
  end
end
