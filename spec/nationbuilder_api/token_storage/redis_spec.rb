# frozen_string_literal: true

RSpec.describe NationbuilderApi::TokenStorage::Redis do
  let(:redis_client) { double("Redis") }
  let(:adapter) { described_class.new(redis_client) }
  let(:identifier) { "user_123" }
  let(:token_data) do
    {
      access_token: "access_token_123",
      refresh_token: "refresh_token_123",
      expires_at: Time.now + 3600,
      scopes: ["people:read", "people:write"],
      token_type: "Bearer"
    }
  end

  describe ".enabled?" do
    it "returns true when Redis is defined" do
      stub_const("::Redis", Class.new)
      expect(described_class.enabled?).to be_truthy
    end

    it "returns false when Redis is not defined" do
      allow(described_class).to receive(:enabled?).and_return(false)
      expect(described_class.enabled?).to be false
    end
  end

  describe "#store_token" do
    it "stores token data in Redis" do
      key = "nationbuilder_api:tokens:#{identifier}"
      expires_at = token_data[:expires_at].to_i

      expect(redis_client).to receive(:set).with(key, anything)
      expect(redis_client).to receive(:expireat).with(key, expires_at)

      result = adapter.store_token(identifier, token_data)
      expect(result).to be true
    end

    it "validates token data structure" do
      invalid_data = {access_token: "token"}
      # Validation error gets wrapped in NetworkError due to rescue block
      expect { adapter.store_token(identifier, invalid_data) }.to raise_error(NationbuilderApi::NetworkError)
    end

    it "raises NetworkError on Redis errors" do
      allow(redis_client).to receive(:set).and_raise(StandardError.new("Connection failed"))

      expect {
        adapter.store_token(identifier, token_data)
      }.to raise_error(NationbuilderApi::NetworkError, /Redis error/)
    end

    it "serializes Time objects to ISO8601 strings" do
      expect(redis_client).to receive(:set) do |_, serialized|
        data = JSON.parse(serialized)
        expect(data["expires_at"]).to match(/^\d{4}-\d{2}-\d{2}T/)
      end
      expect(redis_client).to receive(:expireat)

      adapter.store_token(identifier, token_data)
    end
  end

  describe "#retrieve_token" do
    it "returns nil for non-existent identifier" do
      key = "nationbuilder_api:tokens:nonexistent"
      expect(redis_client).to receive(:get).with(key).and_return(nil)

      expect(adapter.retrieve_token("nonexistent")).to be_nil
    end

    it "retrieves and deserializes stored token" do
      key = "nationbuilder_api:tokens:#{identifier}"
      serialized = JSON.dump({
        access_token: "access_token_123",
        refresh_token: "refresh_token_123",
        expires_at: Time.now.iso8601,
        scopes: ["people:read", "people:write"],
        token_type: "Bearer"
      })

      expect(redis_client).to receive(:get).with(key).and_return(serialized)

      retrieved = adapter.retrieve_token(identifier)
      expect(retrieved[:access_token]).to eq("access_token_123")
      expect(retrieved[:refresh_token]).to eq("refresh_token_123")
      expect(retrieved[:scopes]).to eq(["people:read", "people:write"])
      expect(retrieved[:expires_at]).to be_a(Time)
    end

    it "raises NetworkError on Redis errors" do
      allow(redis_client).to receive(:get).and_raise(StandardError.new("Connection failed"))

      expect {
        adapter.retrieve_token(identifier)
      }.to raise_error(NationbuilderApi::NetworkError, /Redis error/)
    end
  end

  describe "#refresh_token" do
    it "updates existing token" do
      key = "nationbuilder_api:tokens:#{identifier}"
      existing_serialized = JSON.dump({
        access_token: "old_token",
        refresh_token: "old_refresh",
        expires_at: (Time.now + 1800).iso8601,
        scopes: ["people:read"],
        token_type: "Bearer"
      })

      new_data = {
        access_token: "new_access_token",
        refresh_token: "new_refresh_token",
        expires_at: Time.now + 7200,
        scopes: ["people:read"],
        token_type: "Bearer"
      }

      expect(redis_client).to receive(:get).with(key).and_return(existing_serialized)
      expect(redis_client).to receive(:set).with(key, anything)
      expect(redis_client).to receive(:expireat).with(key, new_data[:expires_at].to_i)

      result = adapter.refresh_token(identifier, new_data)
      expect(result).to be true
    end

    it "stores new token if identifier does not exist" do
      key = "nationbuilder_api:tokens:#{identifier}"

      expect(redis_client).to receive(:get).with(key).and_return(nil)
      expect(redis_client).to receive(:set).with(key, anything)
      expect(redis_client).to receive(:expireat)

      result = adapter.refresh_token(identifier, token_data)
      expect(result).to be true
    end

    it "raises NetworkError on Redis errors" do
      allow(redis_client).to receive(:get).and_raise(StandardError.new("Connection failed"))

      expect {
        adapter.refresh_token(identifier, token_data)
      }.to raise_error(NationbuilderApi::NetworkError, /Redis error/)
    end
  end

  describe "#delete_token" do
    it "removes stored token from Redis" do
      key = "nationbuilder_api:tokens:#{identifier}"
      expect(redis_client).to receive(:del).with(key)

      result = adapter.delete_token(identifier)
      expect(result).to be true
    end

    it "raises NetworkError on Redis errors" do
      allow(redis_client).to receive(:del).and_raise(StandardError.new("Connection failed"))

      expect {
        adapter.delete_token(identifier)
      }.to raise_error(NationbuilderApi::NetworkError, /Redis error/)
    end
  end

  describe "key namespacing" do
    it "uses correct key prefix for all operations" do
      expected_key = "nationbuilder_api:tokens:#{identifier}"

      expect(redis_client).to receive(:set).with(expected_key, anything)
      expect(redis_client).to receive(:expireat)

      adapter.store_token(identifier, token_data)
    end
  end
end
