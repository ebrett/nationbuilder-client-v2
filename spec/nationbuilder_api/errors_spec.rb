# frozen_string_literal: true

RSpec.describe NationbuilderApi::Error do
  describe "#initialize" do
    it "accepts a message" do
      error = described_class.new("Test error")
      expect(error.message).to eq("Test error")
    end

    it "accepts a response" do
      response = double("response", body: '{"error": "test_error", "message": "Test message"}')
      error = described_class.new("Test error", response: response)
      expect(error.response).to eq(response)
    end

    it "parses error details from JSON response" do
      response = double("response", body: '{"code": "invalid_request", "message": "Invalid parameter"}')
      error = described_class.new(response: response)
      expect(error.error_code).to eq("invalid_request")
      expect(error.error_message).to eq("Invalid parameter")
    end

    it "handles non-JSON response body" do
      response = double("response", body: "Plain text error")
      error = described_class.new(response: response)
      expect(error.error_message).to eq("Plain text error")
    end
  end

  describe "#retryable?" do
    it "returns false by default" do
      error = described_class.new("Test error")
      expect(error.retryable?).to be false
    end
  end
end

RSpec.describe NationbuilderApi::ConfigurationError do
  it "is not retryable" do
    error = described_class.new("Configuration error")
    expect(error.retryable?).to be false
  end
end

RSpec.describe NationbuilderApi::AuthenticationError do
  it "is not retryable" do
    error = described_class.new("Authentication failed")
    expect(error.retryable?).to be false
  end
end

RSpec.describe NationbuilderApi::RateLimitError do
  describe "#retry_after" do
    it "accepts retry_after parameter" do
      retry_time = Time.now + 120
      error = described_class.new(retry_after: retry_time)
      expect(error.retry_after).to eq(retry_time)
    end

    it "parses Retry-After header as seconds" do
      headers = {"Retry-After" => "120"}
      response = double("response", headers: headers)
      error = described_class.new(response: response)
      expect(error.retry_after).to be_within(2).of(Time.now + 120)
    end

    it "defaults to 60 seconds if no header" do
      response = double("response", headers: {})
      error = described_class.new(response: response)
      expect(error.retry_after).to be_within(2).of(Time.now + 60)
    end
  end

  it "is retryable" do
    error = described_class.new
    expect(error.retryable?).to be true
  end
end

RSpec.describe NationbuilderApi::ServerError do
  it "is retryable" do
    error = described_class.new("Server error")
    expect(error.retryable?).to be true
  end
end

RSpec.describe NationbuilderApi::NetworkError do
  it "is retryable" do
    error = described_class.new("Network error")
    expect(error.retryable?).to be true
  end
end
