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
    # Represents a software component in the CycloneDX BOM specification
    #
    # A component is a self-contained unit of software that can be used as a building block
    # in the architecture of a software system. Components can be of different types like
    # libraries, frameworks, or applications.
    #
    # @attr_reader [String, nil] group The group/organization identifier of the component
    # @attr_reader [String] name The name of the component
    # @attr_reader [String] version The version string of the component
    # @attr_reader [String] type The type of component (must be one of VALID_COMPONENT_TYPES)
    # @attr_reader [String] bomref The unique reference ID for this component in the BOM
    # @attr_reader [String, nil] build_system The build system information
    # @attr_reader [String, nil] vcs The version control system information
    #
    # @example Creating a new component
    #   component = Component.new(
    #     name: "AFNetworking",
    #     version: "4.0.1",
    #     type: "library"
    #   )
    class Component
      VALID_COMPONENT_TYPES = %w[application framework library container operating-system device firmware file].freeze

      attr_reader :group, :name, :version, :type, :bomref, :build_system, :vcs

      def initialize(name:, version:, type:, group: nil, build_system: nil, vcs: nil)
        # cocoapods is a special case to correctly build a purl
        package_type = type == 'cocoapods' ? 'cocoapods' : 'generic'
        @type = type == 'cocoapods' ? 'library' : type

        validate_attributes(name, version, @type, group)

        @group = group
        @name = name
        @version = version
        @build_system = build_system
        @vcs = vcs
        @bomref = build_purl(package_type, name, group, version)
      end

      private

      def build_purl(package_type, name, group, version)
        if group.nil?
          purl_name, subpath = parse_name(name)
        else
          purl_name = "#{CGI.escape(group)}/#{CGI.escape(name)}"
          subpath = ''
        end
        "pkg:#{package_type}/#{purl_name}@#{CGI.escape(version.to_s)}#{subpath}"
      end

      private

      def validate_attributes(name, version, type, group)
        raise ArgumentError, 'Group, if specified, must be non-empty' if exists_and_blank(group)
        raise ArgumentError, 'Name must be non-empty' if missing(name)

        Gem::Version.new(version) # To check that the version string is well-formed
        return if VALID_COMPONENT_TYPES.include?(type)

        raise ArgumentError, "#{type} is not valid component type (#{VALID_COMPONENT_TYPES.join('|')})"
      end

      def parse_name(name)
        purls = name.split('/')
        purl_name = CGI.escape(purls[0])
        subpath = if purls.length > 1
                    "##{name.split('/').drop(1).map do |component|
                      CGI.escape(component)
                    end.join('/')}"
                  else
                    ''
                  end
        [purl_name, subpath]
      end

      def missing(str)
        str.nil? || str.to_s.strip.empty?
      end

      def exists_and_blank(str)
        !str.nil? && str.to_s.strip.empty?
      end
    end
  end
end
