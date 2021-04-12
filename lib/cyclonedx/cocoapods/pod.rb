require 'rubygems/version'
require_relative 'license'

module CycloneDX
  module CocoaPods
    class Pod
      attr_reader :name        # xs:normalizedString
      attr_reader :version     # xs:normalizedString
      attr_reader :checksum    # https://cyclonedx.org/docs/1.2/#type_hashValue (We only use SHA-1 hashes - length == 40)
      attr_reader :author      # xs:normalizedString
      attr_reader :description # xs:normalizedString
      attr_reader :license     # https://cyclonedx.org/docs/1.2/#type_licenseType
                               # We don't currently support several licenses or license expressions https://spdx.github.io/spdx-spec/appendix-IV-SPDX-license-expressions/
      def initialize(name:, version:, checksum: nil)
        raise ArgumentError, "Name must be non empty" if name.nil? || name.to_s.strip.empty?
        Gem::Version.new(version) # To check that the version string is well formed
        raise ArgumentError, "#{checksum} is not valid SHA-1 hash" unless checksum.nil? || checksum =~ /[a-fA-F0-9]{40}/
        @name, @version, @checksum = name.to_s.strip, version, checksum
      end

      def populate(attributes)
        attributes.transform_keys!(&:to_sym)
        populate_author(attributes)
        populate_description(attributes)
        populate_license(attributes)
      end

      def purl
        "pkg:pod/#{CGI.escape(name)}@#{version}"
      end

      def to_s
        "Pod<#{name}, #{version.to_s}>"
      end

      private

      def populate_author(attributes)
        authors = attributes[:author] || attributes[:authors]
        case authors
        when String
          @author = authors
        when Array
          @author = authors.join(', ')
        when Hash
          @author = authors.map { |name, email| "#{name} <#{email}>" }.join(', ')
        else
          @author = nil
        end
      end

      def populate_description(attributes)
        @description = attributes[:description] || attributes[:summary]
      end

      def populate_license(attributes)
        case attributes[:license]
        when String
          @license = License.new(identifier: attributes[:license])
        when Hash
          attributes[:license].transform_keys!(&:to_sym)
          identifier = attributes[:license][:type]
          unless identifier.nil? || identifier.to_s.strip.empty?
            @license = License.new(identifier: identifier)
            @license.text = attributes[:license][:text]
          else
            @license = nil
          end
        else
          @license = nil
        end
      end
    end
  end
end