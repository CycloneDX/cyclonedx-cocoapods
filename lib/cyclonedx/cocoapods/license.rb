require 'json'

module CycloneDX
  module CocoaPods
    class Pod
      class License
        SPDX_LICENSES = JSON.parse(File.read("#{__dir__}/spdx-licenses.json")).freeze
        IDENTIFIER_TYPES = [:id, :name].freeze

        attr_reader   :identifier
        attr_reader   :identifier_type
        attr_accessor :text
        attr_accessor :url

        def initialize(identifier:)
          raise ArgumentError, "License identifier must be non empty" if identifier.nil? || identifier.to_s.strip.empty?

          @identifier = SPDX_LICENSES.find { |license_id| license_id.downcase == identifier.to_s.downcase }
          @identifier_type = @identifier.nil? ? :name : :id
          @identifier ||= identifier
        end
      end
    end
  end
end
