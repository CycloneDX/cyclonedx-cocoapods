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

      def purl
        purl_name = CGI.escape(name.split('/').first)
        source_qualifier = source.nil? || source.source_qualifier.empty? ? '' : "?#{source.source_qualifier.map { |key, value| "#{key}=#{CGI.escape(value)}" }.join('&')}"
        purl_subpath = name.split('/').length > 1 ? "##{name.split('/').drop(1).map { |component| CGI.escape(component) }.join('/')}" : ''
        return "pkg:cocoapods/#{purl_name}@#{CGI.escape(version.to_s)}#{source_qualifier}#{purl_subpath}"
      end

      def add_to_bom(xml)
        xml.component(type: 'library') do
          xml.author author unless author.nil?
          xml.publisher author unless author.nil?
          xml.name name
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
          xml.purl purl
          unless homepage.nil?
            xml.externalReferences do
              xml.reference(type: HOMEPAGE_REFERENCE_TYPE) do
                xml.url homepage
              end
            end
          end
        end
      end

      class License
        def add_to_bom(xml)
          xml.license do
            xml.id identifier if identifier_type == :id
            xml.name identifier if identifier_type == :name
            xml.text_ text unless text.nil?
            xml.url url unless url.nil?
          end
        end
      end
    end

    class Component
      def add_to_bom(xml)
        xml.component(type: type) do
          xml.group group unless group.nil?
          xml.name name
          xml.version version
        end
      end
    end

    class BOMBuilder
      NAMESPACE = 'http://cyclonedx.org/schema/bom/1.4'

      attr_reader :component, :pods

      def initialize(component: nil, pods:)
        @component, @pods = component, pods
      end

      def bom(version: 1)
        raise ArgumentError, "Incorrect version: #{version} should be an integer greater than 0" unless version.to_i > 0

        Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.bom('xmlns': NAMESPACE, 'version':  version.to_i.to_s, 'serialNumber': "urn:uuid:#{SecureRandom.uuid}") do
            bom_metadata(xml)
            xml.components do
              pods.each do |pod|
                pod.add_to_bom(xml)
              end
            end
          end
        end.to_xml
      end

      private

      def bom_metadata(xml)
        xml.metadata do
          xml.timestamp Time.now.getutc.strftime('%Y-%m-%dT%H:%M:%SZ')
          xml.tools do
            xml.tool do
              xml.vendor 'CycloneDX'
              xml.name 'cyclonedx-cocoapods'
              xml.version VERSION
            end
          end
          component.add_to_bom(xml) unless component.nil?
        end
      end
    end
  end
end
