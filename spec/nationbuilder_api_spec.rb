# frozen_string_literal: true

RSpec.describe NationbuilderApi do
  it "has a version number" do
    expect(NationbuilderApi::VERSION).not_to be_nil
  end

  describe "OAuth scope constants" do
    it "defines people scope constants" do
      expect(NationbuilderApi::SCOPE_PEOPLE_READ).to eq("people:read")
      expect(NationbuilderApi::SCOPE_PEOPLE_WRITE).to eq("people:write")
    end

    it "defines donations scope constants" do
      expect(NationbuilderApi::SCOPE_DONATIONS_READ).to eq("donations:read")
      expect(NationbuilderApi::SCOPE_DONATIONS_WRITE).to eq("donations:write")
    end

    it "defines events scope constants" do
      expect(NationbuilderApi::SCOPE_EVENTS_READ).to eq("events:read")
      expect(NationbuilderApi::SCOPE_EVENTS_WRITE).to eq("events:write")
    end
  end

  describe ".configure" do
    it "yields configuration block" do
      NationbuilderApi.configure do |config|
        config.client_id = "test_id"
      end

      expect(NationbuilderApi.configuration.client_id).to eq("test_id")
    end
  end

  describe ".reset_configuration!" do
    it "resets configuration to defaults" do
      NationbuilderApi.configure do |config|
        config.client_id = "test_id"
      end

      NationbuilderApi.reset_configuration!

      expect(NationbuilderApi.configuration.client_id).to be_nil
    end
  end
end
