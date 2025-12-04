# frozen_string_literal: true

require "spec_helper"

RSpec.describe NationbuilderApi::HttpClient, "thread safety" do
  let(:config) do
    config = NationbuilderApi::Configuration.new
    config.client_id = "test_client"
    config.client_secret = "test_secret"
    config.redirect_uri = "https://example.com/callback"
    config.base_url = "https://api.nationbuilder.com/v2"
    config
  end

  let(:token_adapter) { NationbuilderApi::TokenStorage::Memory.new }
  let(:identifier) { "test_user" }
  let(:http_client) { described_class.new(config: config, token_adapter: token_adapter, identifier: identifier) }

  describe "concurrent token refresh" do
    it "prevents race condition when multiple threads detect expired token" do
      # Store an expired token
      expired_token = {
        access_token: "expired_token",
        refresh_token: "refresh_token_123",
        expires_at: Time.now - 3600, # Expired 1 hour ago
        scopes: ["people:read"],
        token_type: "Bearer"
      }
      token_adapter.store_token(identifier, expired_token)

      # Track how many times OAuth.refresh_access_token is called with thread-safe counter
      refresh_count_mutex = Mutex.new
      refresh_count = 0

      # Mock OAuth.refresh_access_token to track calls
      new_token_data = {
        access_token: "new_access_token",
        refresh_token: "new_refresh_token",
        expires_at: Time.now + 3600,
        scopes: ["people:read"],
        token_type: "Bearer"
      }

      allow(NationbuilderApi::OAuth).to receive(:refresh_access_token) do
        refresh_count_mutex.synchronize { refresh_count += 1 }
        # Simulate network delay to increase likelihood of race condition
        sleep(0.01)
        new_token_data
      end

      # Mock HTTP request to avoid actual network calls
      stub_request(:get, "https://api.nationbuilder.com/v2/test")
        .to_return(status: 200, body: '{"data": []}', headers: {"Content-Type" => "application/json"})

      # Launch multiple threads that will all detect the expired token
      threads = 10.times.map do
        Thread.new do
          http_client.get("/test")
        end
      end

      # Wait for all threads to complete
      threads.each(&:join)

      # Verify that refresh was only called once (not 10 times)
      # The mutex should prevent multiple simultaneous refreshes
      expect(refresh_count).to eq(1)
    end

    it "allows concurrent requests when token is not expired" do
      # Store a fresh token
      fresh_token = {
        access_token: "fresh_token",
        refresh_token: "refresh_token_123",
        expires_at: Time.now + 3600, # Expires in 1 hour
        scopes: ["people:read"],
        token_type: "Bearer"
      }
      token_adapter.store_token(identifier, fresh_token)

      # Mock HTTP request
      stub_request(:get, "https://api.nationbuilder.com/v2/test")
        .to_return(status: 200, body: '{"data": []}', headers: {"Content-Type" => "application/json"})

      # Track concurrent execution with thread-safe counters
      counter_mutex = Mutex.new
      concurrent_count = 0
      max_concurrent = 0

      # Stub request execution to track concurrency
      allow_any_instance_of(Net::HTTP).to receive(:request).and_wrap_original do |method, *args|
        counter_mutex.synchronize do
          concurrent_count += 1
          max_concurrent = [max_concurrent, concurrent_count].max
        end
        sleep(0.01) # Simulate some work
        result = method.call(*args)
        counter_mutex.synchronize { concurrent_count -= 1 }
        result
      end

      # Launch multiple threads
      threads = 10.times.map do
        Thread.new do
          http_client.get("/test")
        end
      end

      # Wait for all threads to complete
      threads.each(&:join)

      # Verify that requests were actually concurrent (not serialized)
      expect(max_concurrent).to be > 1
    end
  end
end
