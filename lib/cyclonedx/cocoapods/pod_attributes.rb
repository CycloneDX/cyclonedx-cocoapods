module CycloneDX
  module CocoaPods
    class SearchError < StandardError; end

    module Source
      class CocoaPodsRepository
        attr_accessor :source_manager

        def self.searchable_source(url:, source_manager:)
          source = CocoaPodsRepository.new(url: url)
          source.source_manager = source_manager
          return source
        end

        def attributes_for(pod:)
          specification_sets = @source_manager.search_by_name("^#{Regexp.escape(pod.root_name)}$")
          raise SearchError, "No pod found named #{pod.name}" if specification_sets.length == 0
          raise SearchError, "More than one pod found named #{pod.name}" if specification_sets.length > 1

          paths = specification_sets[0].specification_paths_for_version(pod.version)
          raise SearchError, "Version #{pod.version} not found for pod #{pod.name}" if paths.length == 0

          ::Pod::Specification.from_file(paths[0]).attributes_hash
        end
      end

      class GitRepository
        def attributes_for(pod:)
          {} # TODO: Retrieve attributes from podspec in git repository
        end
      end

      class LocalPod
        def attributes_for(pod:)
          {} # TODO: Retrieve attributes from podspec in local file system
        end
      end

      class Podspec
        def attributes_for(pod:)
          {} # TODO: Retrieve attributes from podspec in specified location
        end
      end
    end


    class Pod
      def complete_information_from_source
        populate(source.attributes_for(pod: self))
      end
    end
  end
end
