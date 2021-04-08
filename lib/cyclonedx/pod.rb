require 'rubygems/version'

module CycloneDX
  module CocoaPods
    class Pod

      attr_reader :name        # xs:normalizedString
      attr_reader :version     # xs:normalizedString
      attr_reader :author      # xs:normalizedString
      attr_reader :description # xs:normalizedString
      def initialize(name:, version:)
        raise ArgumentError, "Name must be non empty" if name.nil? || name.to_s.strip.empty?
        @name, @version = name.to_s.strip, Gem::Version.new(version)
      end

      def populate(attributes)
        attributes.transform_keys!(&:to_sym)
        populate_author(attributes)
        populate_description(attributes)
      end

      def purl
        "pkg:pod/#{name}@#{version}"
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
    end
  end
end