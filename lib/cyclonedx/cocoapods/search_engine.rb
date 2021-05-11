require 'cocoapods-core/version'
require 'cocoapods-core/specification'

module CycloneDX
  module CocoaPods
    class SearchError < StandardError; end

    class SearchEngine
      def initialize(source_manager:)
        @source_manager = source_manager
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
  end
end