# frozen_string_literal: true

RSpec.describe NationbuilderApi::ResponseObjects::Person do
  let(:v2_person_data) do
    {
      data: {
        type: "signup",
        id: "123",
        attributes: {
          first_name: "John",
          last_name: "Doe",
          email: "john@example.com",
          mobile: "+1234567890",
          phone: "+0987654321"
        }
      }
    }
  end

  let(:v1_person_data) do
    {
      id: "123",
      first_name: "John",
      last_name: "Doe",
      email: "john@example.com",
      mobile: "+1234567890"
    }
  end

  describe "#first_name" do
    it "returns first name from V2 data" do
      person = described_class.new(v2_person_data)

      expect(person.first_name).to eq("John")
    end

    it "returns first name from V1 data" do
      person = described_class.new(v1_person_data)

      expect(person.first_name).to eq("John")
    end
  end

  describe "#last_name" do
    it "returns last name from V2 data" do
      person = described_class.new(v2_person_data)

      expect(person.last_name).to eq("Doe")
    end

    it "returns last name from V1 data" do
      person = described_class.new(v1_person_data)

      expect(person.last_name).to eq("Doe")
    end
  end

  describe "#email" do
    it "returns email from V2 data" do
      person = described_class.new(v2_person_data)

      expect(person.email).to eq("john@example.com")
    end

    it "returns email from V1 data" do
      person = described_class.new(v1_person_data)

      expect(person.email).to eq("john@example.com")
    end
  end

  describe "#id" do
    it "returns id from V2 data" do
      person = described_class.new(v2_person_data)

      expect(person.id).to eq("123")
    end

    it "returns id from V1 data" do
      person = described_class.new(v1_person_data)

      expect(person.id).to eq("123")
    end
  end

  describe "#mobile" do
    it "returns mobile from V2 data" do
      person = described_class.new(v2_person_data)

      expect(person.mobile).to eq("+1234567890")
    end

    it "returns mobile from V1 data" do
      person = described_class.new(v1_person_data)

      expect(person.mobile).to eq("+1234567890")
    end
  end

  describe "#phone" do
    it "returns phone from V2 data" do
      person = described_class.new(v2_person_data)

      expect(person.phone).to eq("+0987654321")
    end
  end

  describe "#full_name" do
    it "returns full name when both first and last names present" do
      person = described_class.new(v2_person_data)

      expect(person.full_name).to eq("John Doe")
    end

    it "returns just first name when last name missing" do
      data = {first_name: "John"}
      person = described_class.new(data)

      expect(person.full_name).to eq("John")
    end

    it "returns just last name when first name missing" do
      data = {last_name: "Doe"}
      person = described_class.new(data)

      expect(person.full_name).to eq("Doe")
    end

    it "returns nil when both names missing" do
      person = described_class.new({})

      expect(person.full_name).to be_nil
    end
  end

  describe "#taggings" do
    it "returns taggings from included data" do
      data = {
        data: {
          type: "signup",
          id: "123",
          attributes: {first_name: "John"}
        },
        included: [
          {type: "tagging", id: "1", attributes: {tag: "volunteer"}},
          {type: "tagging", id: "2", attributes: {tag: "donor"}},
          {type: "event", id: "3", attributes: {name: "Rally"}}
        ]
      }
      person = described_class.new(data)
      taggings = person.taggings

      expect(taggings).to be_an(Array)
      expect(taggings.length).to eq(2)
      expect(taggings.first[:type]).to eq("tagging")
      expect(taggings.last[:type]).to eq("tagging")
    end

    it "returns nil when no included data" do
      person = described_class.new(v2_person_data)

      expect(person.taggings).to be_nil
    end

    it "returns empty array when included has no taggings" do
      data = {
        data: {
          type: "signup",
          id: "123",
          attributes: {first_name: "John"}
        },
        included: [
          {type: "event", id: "1"}
        ]
      }
      person = described_class.new(data)

      expect(person.taggings).to eq([])
    end
  end

  describe "backward compatibility" do
    it "supports hash-style access to raw V2 data" do
      person = described_class.new(v2_person_data)

      expect(person[:data]).to eq(v2_person_data[:data])
      expect(person.dig(:data, :attributes, :first_name)).to eq("John")
    end

    it "supports hash-style access to raw V1 data" do
      person = described_class.new(v1_person_data)

      expect(person[:first_name]).to eq("John")
      expect(person[:id]).to eq("123")
    end

    it "supports to_h conversion" do
      person = described_class.new(v2_person_data)

      expect(person.to_h).to eq(v2_person_data)
    end
  end
end
