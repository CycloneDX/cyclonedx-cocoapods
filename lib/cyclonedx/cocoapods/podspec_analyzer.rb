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

require 'cocoapods'
require 'cocoapods-core'
require 'logger'

require_relative 'pod'
require_relative 'pod_attributes'
require_relative 'source'

module CycloneDX
  module CocoaPods
    class PodspecParsingError < StandardError; end

    # Analyzes CocoaPods podspec files to extract component information for CycloneDX BOM generation
    #
    # The PodspecAnalyzer is responsible for:
    # - Validating and loading podspec files from a given path
    # - Parsing podspec contents to extract pod metadata
    # - Converting podspec source information into standardized Source objects
    #
    # @example
    #   analyzer = PodspecAnalyzer.new(logger: Logger.new(STDOUT))
    #   podspec = analyzer.ensure_podspec_is_present(path: '/path/to/project')
    #   pod = analyzer.parse_podspec(podspec)
    #
    class PodspecAnalyzer
      def initialize(logger:)
        @logger = logger
      end

      def ensure_podspec_is_present(options)
        project_dir = Pathname.new(options[:path] || Dir.pwd)
        validate_options(project_dir, options)
        initialize_cocoapods_config(project_dir)

        options[:podspec_path].nil? ? nil : ::Pod::Specification.from_file(options[:podspec_path])
      end

      def parse_podspec(podspec)
        return nil if podspec.nil?

        @logger.debug "Parsing podspec from #{podspec.defined_in_file}"

        Pod.new(
          name: podspec.name,
          version: podspec.version.to_s,
          source: source_from_podspec(podspec),
          checksum: nil
        )
      end

      private

      def validate_options(project_dir, options)
        raise PodspecParsingError, "#{options[:path]} is not a valid directory." unless File.directory?(project_dir)

        podspec_files = Dir.glob("#{project_dir}/*.podspec{.json,}")
        options[:podspec_path] = podspec_files.first unless podspec_files.empty?
      end

      def initialize_cocoapods_config(project_dir)
        ::Pod::Config.instance = nil
        ::Pod::Config.instance.installation_root = project_dir
      end

      def source_from_podspec(podspec)
        if podspec.source[:git]
          Source::GitRepository.new(
            url: podspec.source[:git],
            type: determine_git_ref_type(podspec.source),
            label: determine_git_ref_label(podspec.source)
          )
        end
      end

      def determine_git_ref_type(source)
        return :tag if source[:tag]
        return :commit if source[:commit]
        return :branch if source[:branch]

        nil
      end

      def determine_git_ref_label(source)
        source[:tag] || source[:commit] || source[:branch]
      end
    end
  end
end
