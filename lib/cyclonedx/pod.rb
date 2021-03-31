require 'rubygems/version'

module CycloneDX
  module CocoaPods
    class Pod
      attr_accessor :name
      attr_accessor :version

      def initialize(name:, version:)
        raise ArgumentError, "Name must be non empty" if name.nil? || name.to_s.strip.empty?
        @name, @version = name.to_s.strip, Gem::Version.new(version)
      end

      def purl
        "pkg:pod/#{name}@#{version}"
      end
    end
  end
end