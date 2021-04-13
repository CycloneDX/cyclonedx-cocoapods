require 'nokogiri'
require 'securerandom'

require_relative 'version'

module CycloneDX
  module CocoaPods
    class Pod
      CHECKSUM_ALGORITHM = 'SHA-1'.freeze
      HOMEPAGE_REFERENCE_TYPE = 'website'.freeze

      def add_to_bom(xml)
        xml.component(type: 'library') do
          xml.author author unless author.nil?
          xml.publisher author unless author.nil?
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
          unless homepage.nil?
            xml.externalReferences do
              xml.reference(type: HOMEPAGE_REFERENCE_TYPE) do
                xml.url homepage
              end
            end
          end
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

    class Component
      def add_to_bom(xml)
        xml.component(type: type) do
          xml.group group unless group.nil?
          xml.name name
          xml.version version
        end
      end
    end

    class BOMBuilder
      NAMESPACE = 'http://cyclonedx.org/schema/bom/1.2'.freeze

      attr_reader :component, :pods

      def initialize(component: nil, pods:)
        @component, @pods = component, pods
      end

      def bom(version: 1)
        raise ArgumentError, "Incorrect version: #{version} should be an integer greater than 0" unless version.to_i > 0

        Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.bom('xmlns': NAMESPACE, 'version':  version.to_i.to_s, 'serialNumber': "urn:uuid:#{SecureRandom.uuid}") do
            bom_metadata(xml)
            xml.components do
              pods.each do |pod|
                pod.add_to_bom(xml)
              end
            end
          end
        end.to_xml
      end

      private

      def bom_metadata(xml)
        xml.metadata do
          xml.timestamp Time.now.getutc.strftime('%Y-%m-%dT%H:%M:%SZ')
          xml.tools do
            xml.tool do
              xml.vendor 'CycloneDX'
              xml.name 'cyclonedx-cocoapods'
              xml.version VERSION
            end
            DEPENDENCIES.each do |dependency, version|
              xml.tool do
                xml.name dependency
                xml.version version
              end
            end
          end
          component.add_to_bom(xml) unless component.nil?
        end
      end
    end
  end
end