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
        attr_reader :path

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
