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

require 'json'

module CycloneDX
  module CocoaPods
    class Pod
      class License
        SPDX_LICENSES = JSON.parse(File.read("#{__dir__}/spdx-licenses.json")).freeze
        IDENTIFIER_TYPES = [:id, :name].freeze

        attr_reader   :identifier
        attr_reader   :identifier_type
        attr_accessor :text
        attr_accessor :url

        def initialize(identifier:)
          raise ArgumentError, "License identifier must be non empty" if identifier.nil? || identifier.to_s.strip.empty?

          @identifier = SPDX_LICENSES.find { |license_id| license_id.downcase == identifier.to_s.downcase }
          @identifier_type = @identifier.nil? ? :name : :id
          @identifier ||= identifier
        end
      end
    end
  end
end
