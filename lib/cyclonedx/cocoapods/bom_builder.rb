require 'nokogiri'
require 'securerandom'

module CycloneDX
  module CocoaPods
    class Pod
      CHECKSUM_ALGORITHM = 'SHA-1'.freeze

      def add_to_bom(xml)
        xml.component(type: 'library') do
          xml.author author unless author.nil?
          xml.name name
          xml.version version.to_s
          xml.description description unless description.nil?
          unless checksum.nil?
            xml.hashes do
              xml.hash_(checksum, alg: CHECKSUM_ALGORITHM)
            end
          end
          unless license.nil?
            xml.licenses do
              license.add_to_bom(xml)
            end
          end
          xml.purl purl
        end
      end

      class License
        def add_to_bom(xml)
          xml.license do
            xml.id identifier if identifier_type == :id
            xml.name identifier if identifier_type == :name
            xml.text_ text unless text.nil?
            xml.url url unless url.nil?
          end
        end
      end
    end

    class BOMBuilder
      NAMESPACE = 'http://cyclonedx.org/schema/bom/1.2'.freeze

      attr_reader :pods

      def initialize(pods:)
        @pods = pods
      end

      def bom(version: 1)
        raise ArgumentError, "Incorrect version: #{version} should be an integer greater than 0" unless version.to_i > 0

        Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.bom('xmlns': NAMESPACE, 'version':  version.to_i.to_s, 'serialNumber': "urn:uuid:#{SecureRandom.uuid}") do
            xml.components do
              pods.each do |pod|
                pod.add_to_bom(xml)
              end
            end
          end
        end.to_xml
      end
    end
  end
end