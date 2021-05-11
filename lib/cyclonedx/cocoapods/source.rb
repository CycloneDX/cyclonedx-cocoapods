module CycloneDX
  module CocoaPods
    module Source
      class CocoaPodsRepository
        LEGACY_REPOSITORY = 'https://github.com/CocoaPods/Specs.git'.freeze
        CDN_REPOSITORY = 'trunk'.freeze

        attr_reader :url

        def initialize(url:)
          @url = url
        end

        def source_qualifier
          url == LEGACY_REPOSITORY || url == CDN_REPOSITORY ? {} : { repository_url: url }
        end
      end

      class GitRepository
        VALID_TYPES = [:branch, :tag, :commit].freeze

        attr_reader :url, :type, :label

        def initialize(url:, type: nil, label: nil)
          raise ArgumentError, "Invalid checkout information" if !type.nil? && !VALID_TYPES.include?(type)
          @url, @type, @label = url, type, label
        end

        def source_qualifier
          { vcs_url: (label.nil? ? url : "#{url}@#{label}") }
        end
      end

      class LocalPod
        def initialize(path:)
          @path = path
        end

        def source_qualifier
          # TODO: Should we generate a source qualifier for :path dependencies?
          {}
        end
      end

      class Podspec
        def initialize(url:)
          @url = url
        end

        def source_qualifier
          { download_url: @url }
        end
      end
    end
  end
end
