# frozen_string_literal: true

require "spec_helper"
require "net/http"

RSpec.describe "ResponseWrapper classes" do
  describe NationbuilderApi::HttpClient::ResponseWrapper do
    let(:net_http_response) do
      # Create a mock Net::HTTPResponse object using double
      double("Net::HTTPResponse",
        body: '{"data": "test"}',
        code: "200",
        to_hash: {
          "content-type" => ["application/json"],
          "x-custom-header" => ["custom-value"]
        })
    end

    let(:wrapper) { described_class.new(net_http_response) }

    describe "#initialize" do
      it "stores the Net::HTTPResponse" do
        expect(wrapper.net_http_response).to eq(net_http_response)
      end

      it "extracts the body from Net::HTTPResponse" do
        expect(wrapper.body).to eq('{"data": "test"}')
      end

      it "converts headers to hash using to_hash" do
        expect(wrapper.headers).to be_a(Hash)
        expect(wrapper.headers["content-type"]).to eq(["application/json"])
      end
    end

    describe "#status" do
      it "returns a ResponseStatus object" do
        expect(wrapper.status).to be_a(NationbuilderApi::HttpClient::ResponseStatus)
      end

      it "returns status with correct code as integer" do
        expect(wrapper.status.code).to eq(200)
        expect(wrapper.status.code).to be_a(Integer)
      end
    end
  end

  describe NationbuilderApi::HttpClient::ResponseStatus do
    let(:status) { described_class.new(200) }

    describe "#initialize" do
      it "stores the status code as integer" do
        expect(status.code).to eq(200)
      end
    end

    describe "#to_i" do
      it "returns the status code as integer" do
        expect(status.to_i).to eq(200)
        expect(status.to_i).to be_a(Integer)
      end
    end

    describe "string code conversion" do
      it "handles status code as integer" do
        status_404 = described_class.new(404)
        expect(status_404.code).to eq(404)
        expect(status_404.to_i).to eq(404)
      end
    end
  end
end
