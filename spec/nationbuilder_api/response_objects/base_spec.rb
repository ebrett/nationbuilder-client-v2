# frozen_string_literal: true

RSpec.describe NationbuilderApi::ResponseObjects::Base do
  describe "#initialize" do
    it "stores raw data" do
      data = {name: "Test"}
      obj = described_class.new(data)

      expect(obj.raw_data).to eq(data)
    end

    it "extracts attributes from V1 format (plain JSON)" do
      data = {first_name: "John", last_name: "Doe"}
      obj = described_class.new(data)

      expect(obj.attributes[:first_name]).to eq("John")
      expect(obj.attributes[:last_name]).to eq("Doe")
    end

    it "extracts attributes from V2 format (JSON:API)" do
      data = {
        data: {
          type: "signup",
          id: "123",
          attributes: {
            first_name: "John",
            last_name: "Doe"
          }
        }
      }
      obj = described_class.new(data)

      expect(obj.attributes[:first_name]).to eq("John")
      expect(obj.attributes[:last_name]).to eq("Doe")
      expect(obj.attributes[:id]).to eq("123")
      expect(obj.attributes[:type]).to eq("signup")
    end

    it "includes sideloaded data from JSON:API" do
      data = {
        data: {
          type: "signup",
          id: "123",
          attributes: {first_name: "John"}
        },
        included: [{type: "tagging", id: "1"}]
      }
      obj = described_class.new(data)

      expect(obj.attributes[:included]).to eq([{type: "tagging", id: "1"}])
    end
  end

  describe "attribute access" do
    it "allows method access to attributes" do
      data = {first_name: "John", last_name: "Doe"}
      obj = described_class.new(data)

      expect(obj.first_name).to eq("John")
      expect(obj.last_name).to eq("Doe")
    end

    it "allows string and symbol key access" do
      data = {:first_name => "John", "last_name" => "Doe"}
      obj = described_class.new(data)

      expect(obj.first_name).to eq("John")
      expect(obj.last_name).to eq("Doe")
    end

    it "raises NoMethodError for missing attributes" do
      obj = described_class.new({})

      expect { obj.nonexistent }.to raise_error(NoMethodError)
    end
  end

  describe "#to_h" do
    it "returns original raw data" do
      data = {data: {type: "signup", id: "123"}}
      obj = described_class.new(data)

      expect(obj.to_h).to eq(data)
    end
  end

  describe "hash-like access" do
    let(:data) do
      {
        data: {
          type: "signup",
          id: "123",
          attributes: {first_name: "John"}
        }
      }
    end
    let(:obj) { described_class.new(data) }

    it "supports [] access" do
      expect(obj[:data]).to eq(data[:data])
    end

    it "supports keys method" do
      expect(obj.keys).to eq(data.keys)
    end

    it "supports values method" do
      expect(obj.values).to eq(data.values)
    end

    it "supports key? method" do
      expect(obj.key?(:data)).to be true
      expect(obj.key?(:nonexistent)).to be false
    end

    it "supports each iteration" do
      keys = []
      obj.each { |k, _v| keys << k }

      expect(keys).to eq(data.keys)
    end

    it "supports dig method" do
      expect(obj.dig(:data, :id)).to eq("123")
      expect(obj.dig(:data, :attributes, :first_name)).to eq("John")
    end
  end

  describe "#respond_to_missing?" do
    it "returns true for existing attributes" do
      obj = described_class.new({first_name: "John"})

      expect(obj.respond_to?(:first_name)).to be true
    end

    it "returns false for missing attributes" do
      obj = described_class.new({})

      expect(obj.respond_to?(:nonexistent)).to be false
    end
  end

  describe "#==" do
    it "returns true for objects with same raw data" do
      data = {name: "Test"}
      obj1 = described_class.new(data)
      obj2 = described_class.new(data)

      expect(obj1).to eq(obj2)
    end

    it "returns false for objects with different raw data" do
      obj1 = described_class.new({name: "Test1"})
      obj2 = described_class.new({name: "Test2"})

      expect(obj1).not_to eq(obj2)
    end

    it "returns false for different class types" do
      obj = described_class.new({name: "Test"})

      expect(obj).not_to eq({name: "Test"})
    end
  end
end
