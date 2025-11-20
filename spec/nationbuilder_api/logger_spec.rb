# frozen_string_literal: true

RSpec.describe NationbuilderApi::Logger do
  let(:output) { StringIO.new }
  let(:base_logger) { ::Logger.new(output) }
  let(:logger) { described_class.new(base_logger, log_level: :debug) }

  describe "#sanitize_hash" do
    it "filters sensitive keys" do
      hash = {
        "access_token" => "secret_value",
        "name" => "John",
        "authorization" => "Bearer token"
      }

      sanitized = logger.sanitize_hash(hash)

      expect(sanitized["access_token"]).to eq("[FILTERED]")
      expect(sanitized["authorization"]).to eq("[FILTERED]")
      expect(sanitized["name"]).to eq("John")
    end

    it "handles symbol keys" do
      hash = {
        access_token: "secret",
        name: "John"
      }

      sanitized = logger.sanitize_hash(hash)

      expect(sanitized[:access_token]).to eq("[FILTERED]")
      expect(sanitized[:name]).to eq("John")
    end
  end

  describe "#sanitize_body" do
    it "sanitizes JSON string body" do
      body = '{"access_token": "secret", "name": "John"}'
      sanitized = logger.sanitize_body(body)

      expect(sanitized).to include('"access_token":"[FILTERED]"')
      expect(sanitized).to include('"name":"John"')
    end

    it "handles non-JSON strings" do
      body = "Plain text response"
      sanitized = logger.sanitize_body(body)

      expect(sanitized).to eq("Plain text response")
    end

    it "sanitizes hash body" do
      body = {access_token: "secret", name: "John"}
      sanitized = logger.sanitize_body(body)

      expect(sanitized).to include("[FILTERED]")
      expect(sanitized).to include("John")
    end
  end

  describe "#log_request" do
    it "logs request method and URL" do
      logger.log_request(:get, "https://api.example.com/people")

      output.rewind
      log_content = output.read

      expect(log_content).to include("GET")
      expect(log_content).to include("https://api.example.com/people")
    end

    it "sanitizes headers in debug mode" do
      logger.log_request(:post, "https://api.example.com/people", headers: {"Authorization" => "Bearer secret"})

      output.rewind
      log_content = output.read

      expect(log_content).to include("[FILTERED]")
      expect(log_content).not_to include("secret")
    end
  end

  describe "#log_response" do
    it "logs response status and duration" do
      logger.log_response(200, 245)

      output.rewind
      log_content = output.read

      expect(log_content).to include("200")
      expect(log_content).to include("245ms")
    end
  end
end
