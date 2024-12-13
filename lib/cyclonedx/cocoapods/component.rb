# frozen_string_literal: true

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
# Copyright (c) OWASP Foundation. All Rights Reserved.
#

module CycloneDX
  module CocoaPods
    class Component
      VALID_COMPONENT_TYPES = %w[application framework library container operating-system device firmware file].freeze

      attr_reader :group, :name, :version, :type, :bomref, :build_system, :vcs

      def initialize(name:, version:, type:, group: nil, build_system: nil, vcs: nil)
        raise ArgumentError, 'Group, if specified, must be non empty' if !group.nil? && group.to_s.strip.empty?
        raise ArgumentError, 'Name must be non empty' if name.nil? || name.to_s.strip.empty?

        Gem::Version.new(version) # To check that the version string is well formed
        unless VALID_COMPONENT_TYPES.include?(type)
          raise ArgumentError, "#{type} is not valid component type (#{VALID_COMPONENT_TYPES.join('|')})"
        end

        @group = group
        @name = name
        @version = version
        @type = type
        @build_system = build_system
        @vcs = vcs
        @bomref = "#{name}@#{version}"

        return if group.nil?

        @bomref = "#{group}/#{@bomref}"
      end
    end
  end
end
