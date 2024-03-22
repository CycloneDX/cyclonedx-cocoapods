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
    class PodfileParsingError < StandardError; end

    # Uses cocoapods to analyze the Podfile and Podfile.lock for component dependency information
    class PodfileAnalyzer
      def initialize(logger:, exclude_test_targets: false)
        @logger = logger
        @exclude_test_targets = exclude_test_targets
      end

      def ensure_podfile_and_lock_are_present(options)
        project_dir = Pathname.new(options[:path] || Dir.pwd)

        validate_options(project_dir, options)

        initialize_cocoapods_config(project_dir)

        lockfile = ::Pod::Lockfile.from_file(options[:podfile_lock_path])
        verify_synced_sandbox(lockfile)
        load_plugins(options[:podfile_path])

        [::Pod::Podfile.from_file(options[:podfile_path]), lockfile]
      end

      def parse_pods(podfile, lockfile)
        @logger.debug "Parsing pods from #{podfile.defined_in_file}"
        included_pods, dependencies = create_list_of_included_pods(podfile, lockfile)

        pods = lockfile.pod_names.select { |name| included_pods.include?(name) }.map do |name|
          Pod.new(name: name, version: lockfile.version(name), source: source_for_pod(podfile, lockfile, name),
                  checksum: lockfile.checksum(name))
        end

        pod_dependencies = parse_dependencies(dependencies, podfile, lockfile)

        [pods, pod_dependencies]
      end

      def populate_pods_with_additional_info(pods)
        pods.each do |pod|
          @logger.debug "Completing information for #{pod.name}"
          pod.complete_information_from_source
        end
        pods
      end

      def top_level_deps(podfile, lockfile)
        pods_used = top_level_pods(podfile)
        dependencies_for_pod(pods_used, podfile, lockfile)
      end

      private

      def load_plugins(podfile_path)
        podfile_contents = File.read(podfile_path)
        plugin_syntax = /\s*plugin\s+['"]([^'"]+)['"]/
        plugin_names = podfile_contents.scan(plugin_syntax).flatten

        plugin_names.each do |plugin_name|
          load_one_plugin(plugin_name)
        end
      end

      def load_one_plugin(plugin_name)
        @logger.debug("Loading plugin #{plugin_name}")
        begin
          plugin_spec = Gem::Specification.find_by_name(plugin_name)
          plugin_spec&.activate
          load("#{plugin_spec.gem_dir}/lib/cocoapods_plugin.rb") if plugin_spec
        rescue Gem::LoadError => e
          @logger.warn("Failed to load plugin #{plugin_name}. #{e.message}")
        end
      end

      def validate_options(project_dir, options)
        raise PodfileParsingError, "#{options[:path]} is not a valid directory." unless File.directory?(project_dir)

        options[:podfile_path] = "#{project_dir}Podfile"
        unless File.exist?(options[:podfile_path])
          raise PodfileParsingError, "Missing Podfile in #{project_dir}. Please use the --path option if " \
                                     'not running from the CocoaPods project directory.'
        end

        options[:podfile_lock_path] = "#{project_dir}Podfile.lock"
        return if File.exist?(options[:podfile_lock_path])

        raise PodfileParsingError, "Missing Podfile.lock, please run 'pod install' before generating BOM"
      end

      def parse_dependencies(dependencies, podfile, lockfile)
        pod_dependencies = {}
        dependencies.each do |key, podname_array|
          next unless lockfile.pod_names.include? key

          pod = Pod.new(name: key, version: lockfile.version(key), source: source_for_pod(podfile, lockfile, key),
                        checksum: lockfile.checksum(key))

          pod_dependencies[pod.purl] = dependencies_for_pod(podname_array, podfile, lockfile)
        end

        pod_dependencies
      end

      def dependencies_for_pod(podname_array, podfile, lockfile)
        lockfile.pod_names.select { |name| podname_array.include?(name) }.map do |name|
          pod = Pod.new(name: name,
                        version: lockfile.version(name),
                        source: source_for_pod(podfile, lockfile, name),
                        checksum: lockfile.checksum(name))
          pod.purl
        end
      end

      def initialize_cocoapods_config(project_dir)
        ::Pod::Config.instance.installation_root = project_dir
      end

      def verify_synced_sandbox(lockfile)
        manifest_file = ::Pod::Config.instance.sandbox.manifest
        if manifest_file.nil?
          raise PodfileParsingError,
                "Missing Manifest.lock, please run 'pod install' before generating BOM"
        end
        return if lockfile == manifest_file

        raise PodfileParsingError,
              "The sandbox is not in sync with the Podfile.lock. Run 'pod install' " \
              'or update your CocoaPods installation.'
      end

      def simple_hash_of_lockfile_pods(lockfile)
        pods_hash = {}

        pods_used = lockfile.internal_data['PODS']
        pods_used&.each do |pod|
          map_single_pod(pod, pods_hash)
        end
        pods_hash
      end

      def map_single_pod(pod, pods_hash)
        if pod.is_a?(String)
          # Pods stored as String have no dependencies
          pod_name = pod.split.first
          pods_hash[pod_name] = []
        else
          # Pods stored as a hash have pod name and dependencies.
          pod.each do |pod, dependencies|
            pod_name = pod.split.first
            pods_hash[pod_name] = dependencies.map { |d| d.split.first }
          end
        end
      end

      def append_all_pod_dependencies(pods_used, pods_cache)
        result = pods_used
        original_number = 0
        dependencies_hash = {}

        # Loop adding pod dependencies until we are not adding any more dependencies to the result
        # This brings in all the transitive dependencies of every top level pod.
        # Note this also handles two edge cases:
        #  1. Having a Podfile with no pods used.
        #  2. Having a pod that has a platform-specific dependency that is unused for this Podfile.
        while result.length != original_number
          original_number = result.length

          pods_used.each do |pod_name|
            if pods_cache.key?(pod_name)
              result.push(*pods_cache[pod_name])
              dependencies_hash[pod_name] = pods_cache[pod_name].empty? ? [] : pods_cache[pod_name]
            end
          end

          result = result.uniq
          pods_used = result
        end

        [result, dependencies_hash]
      end

      def top_level_pods(podfile)
        included_targets = podfile.target_definition_list.select { |target| include_target_named(target.label) }
        included_target_names = included_targets.map(&:label)
        @logger.debug "Including all pods for targets: #{included_target_names}"

        top_level_deps = included_targets.map(&:dependencies).flatten.uniq
        top_level_deps.map(&:name).uniq
      end

      def create_list_of_included_pods(podfile, lockfile)
        pods_cache = simple_hash_of_lockfile_pods(lockfile)

        pods_used = top_level_pods(podfile)
        pods_used, dependencies = append_all_pod_dependencies(pods_used, pods_cache)

        [pods_used.sort, dependencies]
      end

      def include_target_named(targetname)
        !@exclude_test_targets || !targetname.downcase.include?('test')
      end

      def cocoapods_repository_source(podfile, lockfile, pod_name)
        @source_manager ||= create_source_manager(podfile)
        Source::CocoaPodsRepository.searchable_source(url: lockfile.spec_repo(pod_name),
                                                      source_manager: @source_manager)
      end

      def git_source(lockfile, pod_name)
        checkout_options = lockfile.checkout_options_for_pod_named(pod_name)
        url = checkout_options[:git]
        %i[tag branch commit].each do |type|
          if checkout_options[type]
            return Source::GitRepository.new(url: url, type: type,
                                             label: checkout_options[type])
          end
        end
        Source::GitRepository.new(url: url)
      end

      def source_for_pod(podfile, lockfile, pod_name)
        root_name = pod_name.split('/').first
        return cocoapods_repository_source(podfile, lockfile, root_name) unless lockfile.spec_repo(root_name).nil?
        return git_source(lockfile, root_name) unless lockfile.checkout_options_for_pod_named(root_name).nil?
        if lockfile.to_hash['EXTERNAL SOURCES'][root_name][:path]
          return Source::LocalPod.new(path: lockfile.to_hash['EXTERNAL SOURCES'][root_name][:path])
        end
        if lockfile.to_hash['EXTERNAL SOURCES'][root_name][:podspec]
          return Source::Podspec.new(url: lockfile.to_hash['EXTERNAL SOURCES'][root_name][:podspec])
        end

        nil
      end

      def create_source_manager(podfile)
        source_manager = ::Pod::Source::Manager.new(::Pod::Config.instance.repos_dir)
        @logger.debug "Parsing sources from #{podfile.defined_in_file}"
        podfile.sources.each do |source|
          @logger.debug "Ensuring #{source} is available for searches"
          source_manager.find_or_create_source_with_url(source)
        end
        @logger.debug 'Source manager successfully created with all needed sources'
        source_manager
      end
    end
  end
end
