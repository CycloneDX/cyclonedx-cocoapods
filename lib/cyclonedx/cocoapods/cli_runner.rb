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

require 'English'
require 'logger'
require 'optparse'

require_relative 'bom_builder'
require_relative 'component'
require_relative 'manufacturer'
require_relative 'podfile_analyzer'

module CycloneDX
  module CocoaPods
    class BOMOutputError < StandardError; end

    # Interprets CLI parameters and runs the main workflow.
    class CLIRunner
      def run
        setup_logger # Needed in case we have errors while processing CLI parameters
        options = parse_options
        setup_logger(verbose: options[:verbose])
        @logger.debug "Running cyclonedx-cocoapods with options: #{options}"

        component, manufacturer, pods, manifest_path, dependencies = analyze(options)

        build_and_write_bom(options, component, manufacturer, pods, manifest_path, dependencies)
      rescue StandardError => e
        @logger.error ([e.message] + e.backtrace).join($INPUT_RECORD_SEPARATOR)
        exit 1
      end

      private

      def parse_options
        parsed_options = {}
        component_types = Component::VALID_COMPONENT_TYPES
        OptionParser.new do |options|
          options.banner = <<~BANNER
            Generates a BOM with the given parameters. BOM component metadata is only generated if the component's name, version, and type are provided using the --name, --version, and --type parameters.
            [version #{CycloneDX::CocoaPods::VERSION}]

            USAGE
              cyclonedx-cocoapods [options]

            OPTIONS
          BANNER

          options.on('--[no-]verbose', 'Show verbose debugging output') do |v|
            parsed_options[:verbose] = v
          end
          options.on('-h', '--help', 'Show help message') do
            puts options
            exit
          end

          options.separator("\n  BOM Generation")
          options.on('-p', '--path path', 'Path to CocoaPods project directory (default: current directory)') do |path|
            parsed_options[:path] = path
          end
          options.on('-o', '--output bom_file_path',
                     'Path to output the bom.xml file to (default: "bom.xml")') do |bom_file_path|
            parsed_options[:bom_file_path] = bom_file_path
          end
          options.on('-b', '--bom-version bom_version', Integer,
                     'Version of the generated BOM (default: "1")') do |version|
            parsed_options[:bom_version] = version
          end
          options.on('-x', '--exclude-test-targets',
                     'Eliminate Podfile targets whose name contains the word "test"') do |exclude|
            parsed_options[:exclude_test_targets] = exclude
          end
          options.on('-s', '--shortened-strings length', Integer,
                     'Trim author, publisher, and purl to <length> characters; this may ' \
                     'cause data loss but can improve compatibility with other systems') do |shortened_strings|
            parsed_options[:trim_strings_length] = shortened_strings
          end

          options.separator("\n  Component Metadata\n")
          options.on('-n', '--name name',
                     '(If specified version and type are also required) Name of the ' \
                     'component for which the BOM is generated') do |name|
            parsed_options[:name] = name
          end
          options.on('-v', '--version version', 'Version of the component for which the BOM is generated') do |version|
            Gem::Version.new(version)
            parsed_options[:version] = version
          rescue StandardError => e
            raise OptionParser::InvalidArgument, e.message
          end
          options.on('-t', '--type type',
                     'Type of the component for which the BOM is generated ' \
                     "(one of #{component_types.join('|')})") do |type|
            unless component_types.include?(type)
              raise OptionParser::InvalidArgument,
                    "Invalid value for component's type (#{type}). It must be one of #{component_types.join('|')}"
            end

            parsed_options[:type] = type
          end
          options.on('-g', '--group group', 'Group of the component for which the BOM is generated') do |group|
            parsed_options[:group] = group
          end
          options.on('-s', '--source source_url',
                     'Optional: The version control system URL of the component for the BOM is generated') do |vcs|
            parsed_options[:vcs] = vcs
          end
          options.on('-b', '--build build_url',
                     'Optional: The build URL of the component for which the BOM is generated') do |build|
            parsed_options[:build] = build
          end

          # Add this section after the "Component Metadata" options group
          options.separator("\n  Manufacturer Metadata\n")
          options.on('--manufacturer-name name',
                     'Name of the manufacturer') do |name|
            parsed_options[:manufacturer_name] = name
          end
          options.on('--manufacturer-url url',
                     'URL of the manufacturer') do |url|
            parsed_options[:manufacturer_url] = url
          end
          options.on('--manufacturer-contact-name name',
                     'Name of the manufacturer contact') do |contact_name|
            parsed_options[:manufacturer_contact_name] = contact_name
          end
          options.on('--manufacturer-email email',
                     'Email of the manufacturer contact') do |email|
            parsed_options[:manufacturer_email] = email
          end
          options.on('--manufacturer-phone phone',
                     'Phone number of the manufacturer contact') do |phone|
            parsed_options[:manufacturer_phone] = phone
          end
        end.parse!

        if !parsed_options[:name].nil? && (parsed_options[:version].nil? || parsed_options[:type].nil?)
          raise OptionParser::InvalidArgument,
                'You must also specify --version and --type if --name is provided'
        end

        parsed_options
      end

      def analyze(options)
        analyzer = PodfileAnalyzer.new(logger: @logger, exclude_test_targets: options[:exclude_test_targets])
        podfile, lockfile = analyzer.ensure_podfile_and_lock_are_present(options)
        pods, dependencies = analyzer.parse_pods(podfile, lockfile)
        analyzer.populate_pods_with_additional_info(pods)

        component = component_from_options(options)
        manufacturer = manufacturer_from_options(options)

        unless component.nil?
          # add top level pods to main component
          top_deps = analyzer.top_level_deps(podfile, lockfile)
          dependencies[component.bomref] = top_deps
        end

        manifest_path = lockfile.defined_in_file
        if manifest_path.absolute?
          # Use the folder that we are building in, then the path to the manifest file
          manifest_path = Pathname.pwd.basename + manifest_path.relative_path_from(Pathname.pwd)
        end

        [component, manufacturer, pods, manifest_path, dependencies]
      end

      def build_and_write_bom(options, component, manufacturer, pods, manifest_path, dependencies)
        builder = BOMBuilder.new(pods: pods, manifest_path: manifest_path,
                                 component: component, manufacturer: manufacturer, dependencies: dependencies)
        bom = builder.bom(version: options[:bom_version] || 1,
                          trim_strings_length: options[:trim_strings_length] || 0)
        write_bom_to_file(bom: bom, options: options)
      end

      def component_from_options(options)
        return unless options[:name]

        Component.new(group: options[:group], name: options[:name], version: options[:version],
                      type: options[:type], build_system: options[:build], vcs: options[:vcs])
      end

      def manufacturer_from_options(options)
        Manufacturer.new(
          name: options[:manufacturer_name],
          url: options[:manufacturer_url],
          contact_name: options[:manufacturer_contact_name],
          email: options[:manufacturer_email],
          phone: options[:manufacturer_phone]
        )
      end

      def setup_logger(verbose: true)
        @logger ||= Logger.new($stdout)
        @logger.level = verbose ? Logger::DEBUG : Logger::INFO
      end

      def write_bom_to_file(bom:, options:)
        bom_file_path = prep_for_bom_write(options)

        begin
          File.write(bom_file_path, bom)
          @logger.info "BOM written to #{bom_file_path}"
        rescue StandardError
          raise BOMOutputError, "Unable to write the BOM to #{bom_file_path}"
        end
      end

      def prep_for_bom_write(options)
        bom_file_path = Pathname.new(options[:bom_file_path] || './bom.xml').expand_path
        bom_dir = bom_file_path.dirname

        begin
          FileUtils.mkdir_p(bom_dir) unless bom_dir.directory?
        rescue StandardError
          raise BOMOutputError, "Unable to create the BOM output directory at #{bom_dir}"
        end

        bom_file_path
      end
    end
  end
end
