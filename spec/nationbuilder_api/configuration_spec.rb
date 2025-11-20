# frozen_string_literal: true

RSpec.describe NationbuilderApi::Configuration do
  describe "#initialize" do
    it "sets default values" do
      config = described_class.new
      expect(config.base_url).to eq("https://api.nationbuilder.com/v2")
      expect(config.timeout).to eq(30)
      expect(config.log_level).to eq(:info)
    end
  end

  describe "#validate!" do
    let(:config) { described_class.new }

    it "raises error when client_id is missing" do
      config.client_secret = "secret"
      config.redirect_uri = "https://example.com/callback"

      expect { config.validate! }.to raise_error(NationbuilderApi::ConfigurationError, /client_id is required/)
    end

    it "raises error when client_secret is missing" do
      config.client_id = "client123"
      config.redirect_uri = "https://example.com/callback"

      expect { config.validate! }.to raise_error(NationbuilderApi::ConfigurationError, /client_secret is required/)
    end

    it "raises error when redirect_uri is missing" do
      config.client_id = "client123"
      config.client_secret = "secret"

      expect { config.validate! }.to raise_error(NationbuilderApi::ConfigurationError, /redirect_uri is required/)
    end

    it "raises error when redirect_uri is not HTTPS" do
      config.client_id = "client123"
      config.client_secret = "secret"
      config.redirect_uri = "http://example.com/callback"

      expect { config.validate! }.to raise_error(NationbuilderApi::ConfigurationError, /must be a valid HTTPS URL/)
    end

    it "raises error when base_url is not HTTPS" do
      config.client_id = "client123"
      config.client_secret = "secret"
      config.redirect_uri = "https://example.com/callback"
      config.base_url = "http://api.example.com"

      expect { config.validate! }.to raise_error(NationbuilderApi::ConfigurationError, /must be a valid HTTPS URL/)
    end

    it "raises error when timeout is not positive" do
      config.client_id = "client123"
      config.client_secret = "secret"
      config.redirect_uri = "https://example.com/callback"
      config.timeout = -5

      expect { config.validate! }.to raise_error(NationbuilderApi::ConfigurationError, /timeout must be a positive number/)
    end

    it "passes validation with valid configuration" do
      config.client_id = "client123"
      config.client_secret = "secret"
      config.redirect_uri = "https://example.com/callback"

      expect { config.validate! }.not_to raise_error
    end
  end

  describe "global configuration" do
    it "allows configuration via configure block" do
      NationbuilderApi.configure do |config|
        config.client_id = "test_client_id"
        config.client_secret = "test_secret"
      end

      expect(NationbuilderApi.configuration.client_id).to eq("test_client_id")
      expect(NationbuilderApi.configuration.client_secret).to eq("test_secret")
    end
  end
end
