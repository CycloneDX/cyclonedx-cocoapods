module CycloneDX
  module CocoaPods
    module Source
      class CocoaPodsRepository
        attr_reader :url

        def initialize(url:)
          @url = url
        end
      end

      class GitRepository
        VALID_TYPES = [:branch, :tag, :commit].freeze

        attr_reader :url, :type, :label

        def initialize(url:, type: nil, label: nil)
          raise ArgumentError, "Invalid checkout information" if !type.nil? && !VALID_TYPES.include?(type)
          @url, @type, @label = url, type, label
        end
      end

      class LocalPod
        def initialize(path:)
          @path = path
        end
      end

      class Podspec
        attr_reader :url

        def initialize(url:)
          @url = url
        end
      end
    end
  end
end
