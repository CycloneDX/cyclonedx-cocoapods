#
# This file is part of CycloneDX CocoaPods
#
# Licensed under the Apache License, Version 2.0 (the “License”);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) José González Gómez. All Rights Reserved.
#

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
          ::Pod::Config.instance.sandbox.specification(pod.name).attributes_hash
        end
      end

      class LocalPod
        def attributes_for(pod:)
          ::Pod::Config.instance.sandbox.specification(pod.name).attributes_hash
        end
      end

      class Podspec
        def attributes_for(pod:)
          ::Pod::Config.instance.sandbox.specification(pod.name).attributes_hash
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
