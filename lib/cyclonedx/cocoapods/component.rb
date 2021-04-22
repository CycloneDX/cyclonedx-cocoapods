module CycloneDX
  module CocoaPods
    class Component
      VALID_COMPONENT_TYPES = %w[application framework library container operating-system device firmware file].freeze

      attr_reader :group, :name, :version, :type

      def initialize(group: nil, name:, version:, type:)
        raise ArgumentError, "Group, if specified, must be non empty" if !group.nil? && group.to_s.strip.empty?
        raise ArgumentError, "Name must be non empty" if name.nil? || name.to_s.strip.empty?
        Gem::Version.new(version) # To check that the version string is well formed
        raise ArgumentError, "#{type} is not valid component type (#{VALID_COMPONENT_TYPES.join('|')})" unless VALID_COMPONENT_TYPES.include?(type)

        @group, @name, @version, @type = group, name, version, type
      end
    end
  end
end
