# frozen_string_literal: true

module NationbuilderApi
  module ResponseObjects
    # Person response object
    # Wraps person data from NationBuilder API (both V1 and V2)
    #
    # @example
    #   person = client.people.show(123)
    #   person.first_name  # => "John"
    #   person.last_name   # => "Doe"
    #   person.email       # => "john@example.com"
    #   person.id          # => "123"
    class Person < Base
      # Get person's full name
      #
      # @return [String, nil] Full name or nil if not available
      def full_name
        return nil unless first_name || last_name
        [first_name, last_name].compact.join(" ")
      end

      # Get person's primary email
      #
      # @return [String, nil] Email address
      def email
        attributes[:email]
      end

      # Get person's first name
      #
      # @return [String, nil] First name
      def first_name
        attributes[:first_name]
      end

      # Get person's last name
      #
      # @return [String, nil] Last name
      def last_name
        attributes[:last_name]
      end

      # Get person's ID
      #
      # @return [String, nil] Person ID
      def id
        attributes[:id]
      end

      # Get person's mobile number
      #
      # @return [String, nil] Mobile number
      def mobile
        attributes[:mobile]
      end

      # Get person's phone number
      #
      # @return [String, nil] Phone number
      def phone
        attributes[:phone]
      end

      # Get person's taggings (if included in response)
      #
      # @return [Array<Hash>, nil] Array of tagging data
      def taggings
        return nil unless attributes[:included]

        attributes[:included].select { |item| item[:type] == "tagging" }
      end
    end
  end
end
