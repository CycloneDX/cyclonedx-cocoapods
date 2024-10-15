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

require 'nokogiri'
require 'securerandom'

require_relative 'version'

module CycloneDX
  module CocoaPods
    module Source
      class CocoaPodsRepository
        LEGACY_REPOSITORY = 'https://github.com/CocoaPods/Specs.git'
        CDN_REPOSITORY = 'trunk'

        def source_qualifier
          url == LEGACY_REPOSITORY || url == CDN_REPOSITORY ? {} : { repository_url: url }
        end
      end

      class GitRepository
        def source_qualifier
          { vcs_url: (label.nil? ? url : "#{url}@#{label}") }
        end
      end

      class LocalPod
        def source_qualifier
          { file_name: @path }
        end
      end

      class Podspec
        def source_qualifier
          { download_url: @url }
        end
      end
    end

    class Pod
      CHECKSUM_ALGORITHM = 'SHA-1'
      HOMEPAGE_REFERENCE_TYPE = 'website'

      def source_qualifier
        return '' if source.nil? || source.source_qualifier.empty?

        "?#{source.source_qualifier.map do |key, value|
              "#{key}=#{CGI.escape(value)}"
            end.join('&')}"
      end

      def purl_subpath
        return '' unless name.split('/').length > 1

        "##{name.split('/').drop(1).map do |component|
              CGI.escape(component)
            end.join('/')}"
      end

      def purl
        purl_name = CGI.escape(name.split('/').first)
        src_qualifier = source_qualifier
        subpath = purl_subpath
        "pkg:cocoapods/#{purl_name}@#{CGI.escape(version.to_s)}#{src_qualifier}#{subpath}"
      end

      def xml_add_author(xml, trim_strings_length)
        return if author.nil?

        if trim_strings_length.zero?
          xml.author author
          xml.publisher author
        else
          xml.author author.slice(0, trim_strings_length)
          xml.publisher author.slice(0, trim_strings_length)
        end
      end

      def xml_add_homepage(xml)
        return if homepage.nil?

        xml.externalReferences do
          xml.reference(type: HOMEPAGE_REFERENCE_TYPE) do
            xml.url homepage
          end
        end
      end

      # Add evidence of the purl identity.
      # See https://github.com/CycloneDX/guides/blob/main/SBOM/en/0x60-Evidence.md for more info
      def xml_add_evidence(xml, manifest_path)
        xml.evidence do
          xml.identity do
            xml.field 'purl'
            xml.confidence '0.6'
            xml.methods_ do
              xml.method_ do
                xml.technique 'manifest-analysis'
                xml.confidence '0.6'
                xml.value manifest_path
              end
            end
          end
        end
      end

      def add_to_bom(xml, manifest_path, trim_strings_length = 0)
        xml.component(type: 'library', 'bom-ref': purl) do
          xml_add_author(xml, trim_strings_length)
          xml.name_ name
          xml.version version.to_s
          xml.description { xml.cdata description } unless description.nil?
          unless checksum.nil?
            xml.hashes do
              xml.hash_(checksum, alg: CHECKSUM_ALGORITHM)
            end
          end
          unless license.nil?
            xml.licenses do
              license.add_to_bom(xml)
            end
          end
          if trim_strings_length.zero?
            xml.purl purl
          else
            xml.purl purl.slice(0, trim_strings_length)
          end
          xml_add_homepage(xml)

          xml_add_evidence(xml, manifest_path)
        end
      end

      class License
        def add_to_bom(xml)
          xml.license do
            xml.id identifier if identifier_type == :id
            xml.name_ identifier if identifier_type == :name
            xml.text_ text unless text.nil?
            xml.url url unless url.nil?
          end
        end
      end
    end

    class Component
      def add_to_bom(xml)
        xml.component(type: type, 'bom-ref': bomref) do
          xml.group group unless group.nil?
          xml.name_ name
          xml.version version
        end
      end
    end

    class BOMBuilder
      NAMESPACE = 'http://cyclonedx.org/schema/bom/1.5'

      attr_reader :component, :pods, :manifest_path, :dependencies

      def initialize(pods:, manifest_path:, component: nil, dependencies: nil)
        @pods = pods.sort_by(&:purl)
        @manifest_path = manifest_path
        @component = component
        @dependencies = dependencies&.sort
      end

      def bom(version: 1, trim_strings_length: 0)
        unless version.to_i.positive?
          raise ArgumentError,
                "Incorrect version: #{version} should be an integer greater than 0"
        end

        unless trim_strings_length.is_a?(Integer) && (trim_strings_length.positive? || trim_strings_length.zero?)
          raise ArgumentError,
                "Incorrect string length: #{trim_strings_length} should be an integer greater than 0"
        end

        unchecked_bom(version: version, trim_strings_length: trim_strings_length)
      end

      private

      # does not verify parameters because the public method does that.
      def unchecked_bom(version: 1, trim_strings_length: 0)
        Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.bom(xmlns: NAMESPACE, version: version.to_i.to_s, serialNumber: "urn:uuid:#{SecureRandom.uuid}") do
            bom_metadata(xml)

            bom_components(xml, pods, manifest_path, trim_strings_length)

            bom_dependencies(xml, dependencies)
          end
        end.to_xml
      end

      def bom_components(xml, pods, manifest_path, trim_strings_length)
        xml.components do
          pods.each do |pod|
            pod.add_to_bom(xml, manifest_path, trim_strings_length)
          end
        end
      end

      def bom_dependencies(xml, dependencies)
        xml.dependencies do
          dependencies&.each do |key, array|
            xml.dependency(ref: key) do
              array.sort.each do |value|
                xml.dependency(ref: value)
              end
            end
          end
        end
      end

      def bom_metadata(xml)
        xml.metadata do
          xml.timestamp Time.now.getutc.strftime('%Y-%m-%dT%H:%M:%SZ')
          bom_tools(xml)
          component&.add_to_bom(xml)
        end
      end

      def bom_tools(xml)
        xml.tools do
          xml.tool do
            xml.vendor 'CycloneDX'
            xml.name_ 'cyclonedx-cocoapods'
            xml.version VERSION
          end
        end
      end
    end
  end
end
