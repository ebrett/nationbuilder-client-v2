# frozen_string_literal: true

RSpec.describe NationbuilderApi::TokenStorage::Memory do
  let(:adapter) { described_class.new }
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
    it "returns true" do
      expect(described_class.enabled?).to be true
    end
  end

  describe "#store_token" do
    it "stores token data" do
      adapter.store_token(identifier, token_data)
      retrieved = adapter.retrieve_token(identifier)
      expect(retrieved[:access_token]).to eq("access_token_123")
    end

    it "validates token data structure" do
      invalid_data = {access_token: "token"}
      expect { adapter.store_token(identifier, invalid_data) }.to raise_error(ArgumentError)
    end
  end

  describe "#retrieve_token" do
    it "returns nil for non-existent identifier" do
      expect(adapter.retrieve_token("nonexistent")).to be_nil
    end

    it "retrieves stored token" do
      adapter.store_token(identifier, token_data)
      retrieved = adapter.retrieve_token(identifier)
      expect(retrieved[:access_token]).to eq("access_token_123")
      expect(retrieved[:refresh_token]).to eq("refresh_token_123")
      expect(retrieved[:scopes]).to eq(["people:read", "people:write"])
    end
  end

  describe "#refresh_token" do
    it "updates existing token" do
      adapter.store_token(identifier, token_data)

      new_data = {
        access_token: "new_access_token",
        refresh_token: "new_refresh_token",
        expires_at: Time.now + 7200,
        scopes: ["people:read"],
        token_type: "Bearer"
      }

      adapter.refresh_token(identifier, new_data)
      retrieved = adapter.retrieve_token(identifier)
      expect(retrieved[:access_token]).to eq("new_access_token")
    end

    it "stores new token if identifier does not exist" do
      adapter.refresh_token(identifier, token_data)
      retrieved = adapter.retrieve_token(identifier)
      expect(retrieved[:access_token]).to eq("access_token_123")
    end
  end

  describe "#delete_token" do
    it "removes stored token" do
      adapter.store_token(identifier, token_data)
      adapter.delete_token(identifier)
      expect(adapter.retrieve_token(identifier)).to be_nil
    end
  end

  describe "thread safety" do
    it "handles concurrent access" do
      threads = 10.times.map do |i|
        Thread.new do
          adapter.store_token("user_#{i}", token_data)
        end
      end

      threads.each(&:join)

      10.times do |i|
        expect(adapter.retrieve_token("user_#{i}")).not_to be_nil
      end
    end
  end
end
