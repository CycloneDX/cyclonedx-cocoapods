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
