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

require 'logger'
require 'optparse'

require_relative 'bom_builder'
require_relative 'component'
require_relative 'podfile_analyzer'

module CycloneDX
  module CocoaPods
    class BOMOutputError < StandardError; end

    class CLIRunner
      def run
        begin
          setup_logger # Needed in case we have errors while processing CLI parameters
          options = parseOptions
          setup_logger(verbose: options[:verbose])
          @logger.debug "Running cyclonedx-cocoapods with options: #{options}"

          analyzer = PodfileAnalyzer.new(logger: @logger, exclude_test_targets: options[:exclude_test_targets])
          podfile, lockfile = analyzer.ensure_podfile_and_lock_are_present(options)
          pods = analyzer.parse_pods(podfile, lockfile)
          analyzer.populate_pods_with_additional_info(pods)

          bom = BOMBuilder.new(component: component_from_options(options), pods: pods).bom(version: options[:bom_version] || 1)
          write_bom_to_file(bom: bom, options: options)
        rescue StandardError => e
          @logger.error ([e.message] + e.backtrace).join($/)
          exit 1
        end
      end


      private


      def parseOptions
        parsedOptions = {}
        component_types = Component::VALID_COMPONENT_TYPES
        OptionParser.new do |options|
          options.banner = <<~BANNER
            Usage: cyclonedx-cocoapods [options]
            Generates a BOM with the given parameters. BOM component metadata is only generated if the component's name and version are provided using the --name and --version parameters.
          BANNER

          options.on('--[no-]verbose', 'Run verbosely') do |v|
            parsedOptions[:verbose] = v
          end
          options.on('-p', '--path path', '(Optional) Path to CocoaPods project directory, current directory if missing') do |path|
            parsedOptions[:path] = path
          end
          options.on('-x', '--exclude-test-targets', 'Eliminate Podfile targets whose name contains the word "test"') do |exclude|
            parsedOptions[:exclude_test_targets] = exclude
          end
          options.on('-o', '--output bom_file_path', '(Optional) Path to output the bom.xml file to') do |bom_file_path|
            parsedOptions[:bom_file_path] = bom_file_path
          end
          options.on('-b', '--bom-version bom_version', Integer, '(Optional) Version of the generated BOM, 1 if not provided') do |version|
            parsedOptions[:bom_version] = version
          end
          options.on('-g', '--group group', '(Optional) Group of the component for which the BOM is generated') do |group|
            parsedOptions[:group] = group
          end
          options.on('-n', '--name name', '(Optional, if specified version and type are also required) Name of the component for which the BOM is generated') do |name|
            parsedOptions[:name] = name
          end
          options.on('-v', '--version version', '(Optional) Version of the component for which the BOM is generated') do |version|
            begin
              Gem::Version.new(version)
              parsedOptions[:version] = version
            rescue StandardError => e
              raise OptionParser::InvalidArgument, e.message
            end
          end
          options.on('-t', '--type type', "(Optional) Type of the component for which the BOM is generated (one of #{component_types.join('|')})") do |type|
            raise OptionParser::InvalidArgument, "Invalid value for component's type (#{type}). It must be one of #{component_types.join('|')}" unless component_types.include?(type)
            parsedOptions[:type] = type
          end
          options.on_tail('-h', '--help', 'Show help message') do
            puts options
            exit
          end
        end.parse!

        raise OptionParser::InvalidArgument, 'You must also specify --version and --type if --name is provided' if !parsedOptions[:name].nil? && (parsedOptions[:version].nil? || parsedOptions[:type].nil?)
        return parsedOptions
      end


      def component_from_options(options)
        Component.new(group: options[:group], name: options[:name], version: options[:version], type: options[:type]) if options[:name]
      end


      def setup_logger(verbose: true)
        @logger ||= Logger.new($stdout)
        @logger.level = verbose ? Logger::DEBUG : Logger::INFO
      end


      def write_bom_to_file(bom:, options:)
        bom_file_path = Pathname.new(options[:bom_file_path] || './bom.xml').expand_path
        bom_dir = bom_file_path.dirname

        begin
          FileUtils.mkdir_p(bom_dir) unless bom_dir.directory?
        rescue
          raise BOMOutputError, "Unable to create the BOM output directory at #{bom_dir}"
        end

        begin
          File.open(bom_file_path, 'w') { |file| file.write(bom) }
          @logger.info "BOM written to #{bom_file_path}"
        rescue
          raise BOMOutputError, "Unable to write the BOM to #{bom_file_path}"
        end
      end
    end
  end
end
