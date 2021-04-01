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
      NAMESPACE = 'http://cyclonedx.org/schema/bom/1.1'.freeze
      VERSION   = '1'.freeze

      attr_reader :pods, :uuid
      attr_reader :bom

      def initialize(pods:)
        @pods = pods
        @uuid = SecureRandom.uuid
      end

      def bom
        @bom ||= Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.bom('xmlns' => NAMESPACE, 'version' => VERSION, 'serialNumber' => "urn:uuid:#{uuid}") do
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