# frozen_string_literal: true

RSpec.describe NationbuilderApi::Resources::Tags do
  let(:client) do
    instance_double(
      NationbuilderApi::Client,
      get: nil
    )
  end

  subject(:tags) { described_class.new(client) }

  describe "#list" do
    it "makes GET request to /api/v1/tags" do
      expect(client).to receive(:get).with("/api/v1/tags", params: {})
      tags.list
    end

    it "returns tags data in V1 format" do
      tags_data = {
        results: [
          {name: "volunteer", path: "/tags/volunteer"},
          {name: "donor", path: "/tags/donor"},
          {name: "activist", path: "/tags/activist"}
        ]
      }

      allow(client).to receive(:get).and_return(tags_data)
      result = tags.list

      expect(result).to eq(tags_data)
      expect(result[:results].length).to eq(3)
      expect(result[:results].first[:name]).to eq("volunteer")
    end
  end
end
