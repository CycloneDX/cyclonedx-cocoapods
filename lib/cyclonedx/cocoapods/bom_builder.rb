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

      def to_json_component(manifest_path, trim_strings_length = 0)
        {
          type: 'library',
          'bom-ref': purl,
          author: trim(author, trim_strings_length),
          publisher: trim(author, trim_strings_length),
          name: name,
          version: version.to_s,
          description: description,
          hashes: generate_json_hashes,
          licenses: generate_json_licenses,
          purl: purl,
          externalReferences: generate_json_external_references,
          evidence: generate_json_evidence(manifest_path)
        }.compact
      end

      def generate_json_external_references
        refs = []
        refs << { type: HOMEPAGE_REFERENCE_TYPE, url: homepage } if homepage
        refs.empty? ? nil : refs
      end

      def generate_json_evidence(manifest_path)
        {
          identity: {
            field: 'purl',
            confidence: 0.6,
            methods: [
              {
                technique: 'manifest-analysis',
                confidence: 0.6,
                value: manifest_path
              }
            ]
          }
        }
      end

      class License
        def to_json_component
          {
            license: {
              id: identifier_type == :id ? identifier : nil,
              name: identifier_type == :name ? identifier : nil,
              text: text,
              url: url
            }.compact
          }
        end

        def add_to_bom(xml)
          xml.license do
            xml.id identifier if identifier_type == :id
            xml.name_ identifier if identifier_type == :name
            xml.text_ text unless text.nil?
            xml.url url unless url.nil?
          end
        end
      end

      private

      def generate_json_licenses
        license ? [license.to_json_component] : nil
      end

      def generate_json_hashes
        checksum ? [{ alg: CHECKSUM_ALGORITHM, content: checksum }] : nil
      end

      def trim(str, trim_strings_length)
        trim_strings_length.zero? ? str : str&.slice(0, trim_strings_length)
      end
    end

    class Component
      def add_to_bom(xml)
        xml.component(type: type, 'bom-ref': bomref) do
          xml.group group unless group.nil?
          xml.name_ name
          xml.version version

          if !build_system.nil? || !vcs.nil?
            xml.externalReferences do
              if build_system
                xml.reference(type: 'build-system') do
                  xml.url build_system
                end
              end

              if vcs
                xml.reference(type: 'vcs') do
                  xml.url vcs
                end
              end
            end
          end
          xml.purl bomref
        end
      end

      def to_json_component
        {
          type: type,
          'bom-ref': bomref,
          group: group,
          name: name,
          version: version,
          externalReferences: generate_json_external_references
        }.compact
      end

      private

      def generate_json_external_references
        refs = []
        refs << { type: 'build-system', url: build_system } if build_system
        refs << { type: 'vcs', url: vcs } if vcs
        refs.empty? ? nil : refs
      end
    end

    # Represents manufacturer information in a CycloneDX BOM
    # Handles generation of manufacturer XML elements including basic info and contact details
    # Used when generating BOM metadata for CycloneDX specification
    class Manufacturer
      def add_to_bom(xml)
        return if all_attributes_nil?

        xml.manufacturer do
          add_basic_info(xml)
          add_contact_info(xml)
        end
      end

      def to_json_component
        return nil if all_attributes_nil?

        {
          name: name,
          url: url,
          contact: [generate_json_contact].compact
        }.compact
      end

      private

      def generate_json_contact
        return nil if contact_info_nil?

        {
          name: contact_name,
          email: email,
          phone: phone
        }.compact
      end

      def all_attributes_nil?
        [name, url, contact_name, email, phone].all?(&:nil?)
      end

      def add_basic_info(xml)
        xml.name_ name unless name.nil?
        xml.url url unless url.nil?
      end

      def add_contact_info(xml)
        return if contact_info_nil?

        xml.contact do
          xml.name_ contact_name unless contact_name.nil?
          xml.email email unless email.nil?
          xml.phone phone unless phone.nil?
        end
      end

      def contact_info_nil?
        contact_name.nil? && email.nil? && phone.nil?
      end
    end

    # Turns the internal model data into an XML bom.
    class BOMBuilder
      NAMESPACE = 'http://cyclonedx.org/schema/bom/1.6'

      attr_reader :component, :pods, :manifest_path, :dependencies, :manufacturer

      def initialize(pods:, manifest_path:, component: nil, dependencies: nil, manufacturer: nil)
        @pods = pods.sort_by(&:purl)
        @manifest_path = manifest_path
        @component = component
        @dependencies = dependencies&.sort
        @manufacturer = manufacturer
      end

      def bom(version: 1, trim_strings_length: 0, format: :xml)
        validate_bom_args(version, trim_strings_length, format)
        unchecked_bom(version: version, trim_strings_length: trim_strings_length, format: format)
      end

      private

      def validate_bom_args(version, trim_strings_length, format)
        unless version.to_i.positive?
          raise ArgumentError,
                "Incorrect version: #{version} should be an integer greater than 0"
        end

        unless trim_strings_length.is_a?(Integer) && (trim_strings_length.positive? || trim_strings_length.zero?)
          raise ArgumentError,
                "Incorrect string length: #{trim_strings_length} should be an integer greater than 0"
        end

        unless %i[xml json].include?(format)
          raise ArgumentError,
                "Incorrect format: #{format} should be either :xml or :json"
        end
      end

      # does not verify parameters because the public method does that.
      def unchecked_bom(version:, trim_strings_length:, format:)
        case format
        when :json
          generate_json(version: version, trim_strings_length: trim_strings_length)
        when :xml
          generate_xml(version: version, trim_strings_length: trim_strings_length)
        end
      end

      def generate_xml(version:, trim_strings_length:)
        Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.bom(xmlns: NAMESPACE, version: version.to_i.to_s, serialNumber: "urn:uuid:#{SecureRandom.uuid}") do
            bom_metadata(xml)
            bom_components(xml, pods, manifest_path, trim_strings_length)
            bom_dependencies(xml, dependencies)
          end
        end.to_xml
      end

      def generate_json(version:, trim_strings_length:)
        {
          '$schema': 'https://cyclonedx.org/schema/bom-1.6.schema.json',
          bomFormat: 'CycloneDX',
          specVersion: version.to_s,
          serialNumber: "urn:uuid:#{SecureRandom.uuid}",
          version: 1,
          metadata: generate_json_metadata,
          components: generate_json_components(trim_strings_length),
          dependencies: generate_json_dependencies
        }.to_json
      end

      def generate_json_metadata
        {
          timestamp: Time.now.getutc.strftime('%Y-%m-%dT%H:%M:%SZ'),
          tools: {
            components: [{
              type: 'application',
              group: 'CycloneDX',
              name: 'cyclonedx-cocoapods',
              version: VERSION
            }]
          },
          component: component&.to_json_component,
          manufacturer: manufacturer&.to_json_component
        }.compact
      end

      def generate_json_components(trim_strings_length)
        pods.map { |pod| pod.to_json_component(manifest_path, trim_strings_length) }
      end

      def generate_json_dependencies
        return nil unless dependencies

        dependencies.map do |ref, deps|
          {
            ref: ref,
            dependsOn: deps.sort
          }
        end
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
          manufacturer&.add_to_bom(xml)
        end
      end
      def bom_tools(xml)
        xml.tools do
          xml.components do
            xml.component(type: 'application') do
              xml.group 'CycloneDX'
              xml.name_ 'cyclonedx-cocoapods'
              xml.version VERSION
            end
          end
        end
      end
    end
  end
end
