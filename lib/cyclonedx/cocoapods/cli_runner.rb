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
# Copyright (c) José González Gómez. All Rights Reserved.
#

require 'optparse'
require 'logger'
require 'cocoapods'

require_relative 'component'
require_relative 'pod'
require_relative 'pod_attributes'
require_relative 'source'
require_relative 'bom_builder'

module CycloneDX
  module CocoaPods
    class PodfileParsingError < StandardError; end
    class BOMOutputError < StandardError; end

    class CLIRunner
      def run
        begin
          setup_logger # Needed in case we have errors while processing CLI parameters
          options = parseOptions
          setup_logger(verbose: options[:verbose])
          @logger.debug "Running cyclonedx-cocoapods with options: #{options}"

          podfile, lockfile = ensure_podfile_and_lock_are_present(options)
          pods = parse_pods(podfile, lockfile)

          populate_pods_with_additional_info(pods)

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


      def ensure_podfile_and_lock_are_present(options)
        project_dir = Pathname.new(options[:path] || Dir.pwd)
        raise PodfileParsingError, "#{options[:path]} is not a valid directory." unless File.directory?(project_dir)
        options[:podfile_path] = project_dir + 'Podfile'
        raise PodfileParsingError, "Missing Podfile in #{project_dir}. Please use the --path option if not running from the CocoaPods project directory." unless File.exist?(options[:podfile_path])
        options[:podfile_lock_path] = project_dir + 'Podfile.lock'
        raise PodfileParsingError, "Missing Podfile.lock, please run pod install before generating BOM" unless File.exist?(options[:podfile_lock_path])
        return ::Pod::Podfile.from_file(options[:podfile_path]), ::Pod::Lockfile.from_file(options[:podfile_lock_path])
      end


      def cocoapods_repository_source(podfile, lockfile, pod_name)
        @source_manager ||= create_source_manager(podfile)
        return Source::CocoaPodsRepository.searchable_source(url: lockfile.spec_repo(pod_name), source_manager: @source_manager)
      end


      def git_source(lockfile, pod_name)
        checkout_options = lockfile.checkout_options_for_pod_named(pod_name)
        url = checkout_options[:git]
        [:tag, :branch, :commit].each do |type|
          return Source::GitRepository.new(url: url, type: type, label: checkout_options[type]) if checkout_options[type]
        end
        return Source::GitRepository.new(url: url)
      end


      def source_for_pod(podfile, lockfile, pod_name)
        root_name = pod_name.split('/').first
        return cocoapods_repository_source(podfile, lockfile, root_name) unless lockfile.spec_repo(root_name).nil?
        return git_source(lockfile, root_name) unless lockfile.checkout_options_for_pod_named(root_name).nil?
        return Source::LocalPod.new(path: lockfile.to_hash['EXTERNAL SOURCES'][root_name][:path]) if lockfile.to_hash['EXTERNAL SOURCES'][root_name][:path]
        return Source::Podspec.new(url: lockfile.to_hash['EXTERNAL SOURCES'][root_name][:podspec]) if lockfile.to_hash['EXTERNAL SOURCES'][root_name][:podspec]
        return nil
      end


      def parse_pods(podfile, lockfile)
        @logger.debug "Parsing pods from #{podfile.defined_in_file}"
        return lockfile.pod_names.map do |name|
          Pod.new(name: name, version: lockfile.version(name), source: source_for_pod(podfile, lockfile, name), checksum: lockfile.checksum(name))
        end
      end


      def create_source_manager(podfile)
        sourceManager = ::Pod::Source::Manager.new(::Pod::Config::instance.repos_dir)
        @logger.debug "Parsing sources from #{podfile.defined_in_file}"
        podfile.sources.each do |source|
          @logger.debug "Ensuring #{source} is available for searches"
          sourceManager.find_or_create_source_with_url(source)
        end
        @logger.debug "Source manager successfully created with all needed sources"
        return sourceManager
      end


      def populate_pods_with_additional_info(pods)
        pods.each do |pod|
          @logger.debug "Completing information for #{pod.name}"
          pod.complete_information_from_source
        end
        return pods
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
