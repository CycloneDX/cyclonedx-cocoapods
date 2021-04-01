require 'nokogiri'
require 'securerandom'

module CycloneDX
  module CocoaPods
    class Pod
      def add_component_to_bom(xml)
        xml.component(type: 'library') do
          xml.name name
          xml.version version.to_s
          xml.purl purl
        end
      end
    end

    class BOMBuilder
      NAMESPACE = 'http://cyclonedx.org/schema/bom/1.2'.freeze

      attr_reader :pods, :uuid

      def initialize(pods:)
        @pods = pods
        @uuid = SecureRandom.uuid
      end

      def bom(version: 1)
        raise ArgumentError, "#{version} should be an integer greater than 0" unless version.to_i > 0

        @bom ||= Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.bom('xmlns' => NAMESPACE, 'version' => version.to_i.to_s, 'serialNumber' => "urn:uuid:#{uuid}") do
            xml.components do
              pods.each do |pod|
                pod.add_component_to_bom(xml)
              end
            end
          end
        end.to_xml
      end
    end
  end
end