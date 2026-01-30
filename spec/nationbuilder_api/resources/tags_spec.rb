# frozen_string_literal: true

RSpec.describe NationbuilderApi::Resources::Tags do
  let(:client) do
    instance_double(
      NationbuilderApi::Client,
      get: nil,
      put: nil,
      delete: nil
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

  describe "#bulk_apply" do
    it "applies tag to multiple people" do
      person_ids = [1, 2, 3]
      person_ids.each do |id|
        expected_body = {tagging: {tag: "volunteer"}}
        expect(client).to receive(:put)
          .with("/api/v1/people/#{id}/taggings", body: expected_body)
      end

      tags.bulk_apply("volunteer", person_ids)
    end

    it "returns array of responses" do
      allow(client).to receive(:put).and_return({status: "success"})
      result = tags.bulk_apply("volunteer", [1, 2])

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first).to eq({status: "success"})
    end

    it "handles empty person_ids array" do
      expect(client).not_to receive(:put)
      result = tags.bulk_apply("volunteer", [])

      expect(result).to eq([])
    end
  end

  describe "#bulk_remove" do
    it "removes tag from multiple people" do
      person_ids = [1, 2, 3]
      person_ids.each do |id|
        expect(client).to receive(:delete)
          .with("/api/v1/people/#{id}/taggings/volunteer")
      end

      tags.bulk_remove("volunteer", person_ids)
    end

    it "returns array of responses" do
      allow(client).to receive(:delete).and_return({status: "deleted"})
      result = tags.bulk_remove("volunteer", [1, 2])

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first).to eq({status: "deleted"})
    end

    it "handles empty person_ids array" do
      expect(client).not_to receive(:delete)
      result = tags.bulk_remove("volunteer", [])

      expect(result).to eq([])
    end

    it "handles tag names with spaces" do
      expect(client).to receive(:delete)
        .with("/api/v1/people/1/taggings/needs follow-up")

      tags.bulk_remove("needs follow-up", [1])
    end
  end
end
