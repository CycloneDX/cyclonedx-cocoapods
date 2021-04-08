require_relative 'spdx_licenses'

module CycloneDX
  module CocoaPods
    class Pod
      class License
        IDENTIFIER_TYPES = [:id, :name].freeze

        attr_reader   :identifier
        attr_reader   :identifier_type
        attr_accessor :text
        attr_accessor :url

        def initialize(identifier:)
          raise ArgumentError, "License identifier must be non empty" if identifier.nil? || identifier.to_s.strip.empty?

          @identifier = SPDX_LICENSES.keys.find { |license_id| license_id.downcase == identifier.to_s.downcase }
          @identifier_type = @identifier.nil? ? :name : :id
          @identifier ||= identifier
        end
      end
    end
  end
end
