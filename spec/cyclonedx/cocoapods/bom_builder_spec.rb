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

require 'rspec'
require 'rspec/matchers'
require 'equivalent-xml'
require 'cyclonedx/cocoapods/version'
require 'cyclonedx/cocoapods/bom_builder'
require 'cyclonedx/cocoapods/pod'
require 'cyclonedx/cocoapods/component'
require 'cyclonedx/cocoapods/manufacturer'

RSpec.describe CycloneDX::CocoaPods::Pod do
  let(:pod_name) { 'Alamofire' }
  let(:pod_version) { '5.4.2' }
  let(:checksum) { '9a8ccc3a24b87624f4b40883adab3d98a9fdc00d' }
  let(:author) { 'Darth Vader' }
  let(:summary) { 'Elegant HTTP Networking in Swift' }
  let(:homepage) { 'https://github.com/Alamofire/Alamofire' }

  let(:pod) { described_class.new(name: pod_name, version: pod_version, checksum: checksum) }
  let(:xml) do
    Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      pod.add_to_bom(xml, 'unused.lock')
    end.to_xml)
  end
  let(:json) do
    pod.to_json_component('unused.lock')
  end
  let(:json_short) do
    pod.to_json_component('unused.lock', 7)
  end

  let(:shortXML) do
    Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      pod.add_to_bom(xml, 'unused.lock', 7)
    end.to_xml)
  end

  context 'when generating a pod component in a BOM' do
    it 'should generate a root component of type library' do
      expect(xml.at('/component')).not_to be_nil
      expect(xml.at('/component')['type']).to eql('library')
    end
    context 'for JSON' do
      it 'should generate a component of type library' do
        expect(json[:type]).not_to be_nil
        expect(json[:type]).to eql('library')
      end
    end

    it 'should generate a correct component name' do
      expect(xml.at('/component/name')).not_to be_nil
      expect(xml.at('/component/name').text).to eql(pod.name)
    end
    context 'for JSON' do
      it 'should generate a correct component name' do
        expect(json[:name]).not_to be_nil
        expect(json[:name]).to eql(pod.name)
      end
    end

    it 'should generate a correct component version' do
      expect(xml.at('/component/version')).not_to be_nil
      expect(xml.at('/component/version').text).to eql(pod.version.to_s)
    end

    context 'for JSON' do
      it 'should generate a correct component version' do
        expect(json[:version]).not_to be_nil
        expect(json[:version]).to eql(pod.version.to_s)
      end
    end

    it 'should generate a correct component purl' do
      expect(xml.at('/component/purl')).not_to be_nil
      expect(xml.at('/component/purl').text).to eql(pod.purl)
    end
    context 'for JSON' do
      it 'should generate a correct component purl' do
        expect(json[:purl]).not_to be_nil
        expect(json[:purl]).to eql(pod.purl)
      end
    end

    context 'when shortening to a limited string length' do
      it 'should truncate the purl to the right number of characters' do
        expect(shortXML.at('/component/purl')).not_to be_nil
        expect(shortXML.at('/component/purl').text).to eql('pkg:coc')
      end
    end

    context 'when not having an author' do
      it 'shouldn\'t generate a component author' do
        expect(xml.at('/component/author')).to be_nil
        expect(xml.at('/component/publisher')).to be_nil
      end

      context 'for JSON' do
        it 'shouldn\'t generate a component author' do
          expect(json[:author]).to be_nil
          expect(json[:publisher]).to be_nil
        end
      end
    end

    context 'when having an author' do
      let(:pod) do
        described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(author: author)
      end

      it 'should generate a correct component author' do
        expect(xml.at('/component/author')).not_to be_nil
        expect(xml.at('/component/author').text).to eql(pod.author)
        expect(xml.at('/component/publisher')).not_to be_nil
        expect(xml.at('/component/publisher').text).to eql(pod.author)
      end

      context 'for JSON' do
        it 'should generate a correct component author' do
          expect(json[:author]).not_to be_nil
          expect(json[:author]).to eql(pod.author)
          expect(json[:publisher]).not_to be_nil
          expect(json[:publisher]).to eql(pod.author)
        end
      end

      context 'when shortening to a limited string length' do
        it 'should truncate the author to the right number of characters' do
          expect(shortXML.at('/component/author')).not_to be_nil
          expect(shortXML.at('/component/author').text).to eql('Darth V')
          expect(shortXML.at('/component/publisher')).not_to be_nil
          expect(shortXML.at('/component/publisher').text).to eql('Darth V')
        end

        context 'for JSON' do
          it 'should truncate the author to the right number of characters' do
            expect(json_short[:author]).not_to be_nil
            expect(json_short[:author]).to eql('Darth V')
            expect(json_short[:publisher]).not_to be_nil
            expect(json_short[:publisher]).to eql('Darth V')
          end
        end
      end
    end

    context 'when not having a description' do
      it 'shouldn\'t generate a component description' do
        expect(xml.at('/component/description')).to be_nil
      end

      context 'for JSON' do
        it 'shouldn\'t generate a component description' do
          expect(json[:description]).to be_nil
        end
      end
    end

    context 'when having a description' do
      let(:pod) do
        described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(summary: summary)
      end

      it 'should generate a correct component description' do
        expect(xml.at('/component/description')).not_to be_nil
        expect(xml.at('/component/description').text).to eql(pod.description)
      end

      context 'for JSON' do
        it 'should generate a correct component description' do
          expect(json[:description]).not_to be_nil
          expect(json[:description]).to eql(pod.description)
        end
      end
    end

    context 'when having a null byte description' do
      let(:pod) do
        described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(summary: "'\0'")
      end

      it 'should generate a correct component description' do
        expect(xml.at('/component/description')).not_to be_nil
        expect(xml.at('/component/description').text).to eql("'\\x00'")
      end
    end

    context 'when not having a checksum' do
      let(:pod) { described_class.new(name: pod_name, version: pod_version) }

      it 'shouldn\'t generate a component hash' do
        expect(xml.at('/component/hashes')).to be_nil
      end

      context 'for JSON' do
        it 'shouldn\'t generate a component hash' do
          expect(json[:hashes]).to be_nil
        end
      end
    end

    context 'when having a checksum' do
      it 'should generate a correct component hash' do
        expect(xml.at('/component/hashes/hash')).not_to be_nil
        # CocoaPods always uses SHA-1
        expect(xml.at('/component/hashes/hash')['alg']).to eq(described_class::CHECKSUM_ALGORITHM)
        expect(xml.at('/component/hashes/hash').text).to eql(pod.checksum)
      end
      context 'for JSON' do
        it 'should generate a correct component hash' do
          expect(json[:hashes]).not_to be_nil
          expect(json[:hashes][0][:alg]).to eq(described_class::CHECKSUM_ALGORITHM)
          expect(json[:hashes][0][:content]).to eql(pod.checksum)
        end
      end
    end

    context 'when not having a license' do
      it 'shouldn\'t generate a license list' do
        expect(xml.at('/component/licenses')).to be_nil
      end
      context 'for JSON' do
        it 'shouldn\'t generate a license list' do
          expect(json[:licenses]).to be_nil
        end
      end
    end

    context 'when having a license' do
      let(:pod) do
        described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(license: 'MIT')
      end

      it 'should generate a child licenses node' do
        expect(xml.at('/component/licenses')).not_to be_nil
      end
      context 'for JSON' do
        it 'should generate a correct license list' do
          expect(json[:licenses]).not_to be_nil
        end
      end

      it 'should properly delegate license node generation' do
        license_generated_from_pod = xml.xpath('/component/licenses/license')[0]

        license = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          pod.license.add_to_bom(xml)
        end.to_xml).at('/license')

        expect(license_generated_from_pod).to be_equivalent_to(license)
      end
    end

    context 'when not having a homepage' do
      it 'shouldn\'t generate an external references list' do
        expect(xml.at('/component/externalReferences')).to be_nil
      end
      context 'for JSON' do
        it 'shouldn\'t generate an external references list' do
          expect(json[:externalReferences]).to be_nil
        end
      end
    end

    context 'when having a homepage' do
      let(:pod) do
        described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(homepage: homepage)
      end

      it 'should properly generate a component external references list' do
        expect(xml.at('/component/externalReferences')).not_to be_nil
        expect(xml.at('/component/externalReferences/reference')).not_to be_nil
        actual = xml.at('/component/externalReferences/reference')['type']
        expect(actual).to eq(described_class::HOMEPAGE_REFERENCE_TYPE)
        expect(xml.at('/component/externalReferences/reference/url')).not_to be_nil
        expect(xml.at('/component/externalReferences/reference/url').text).to eq(homepage)
      end

      context 'for JSON' do
        it 'should properly generate a component external references list' do
          expect(json[:externalReferences]).not_to be_nil
          expect(json[:externalReferences].length).to eq(1)
          expect(json[:externalReferences][0][:type]).to eq(described_class::HOMEPAGE_REFERENCE_TYPE)
          expect(json[:externalReferences][0][:url]).to eq(homepage)
        end
      end
    end
  end

  context 'when generating a pod component in a BOM for JSON' do
    it 'should generate a root component of type library' do
      expect(xml.at('/component')).not_to be_nil
      expect(xml.at('/component')['type']).to eql('library')
    end
    context 'for JSON' do
      it 'should generate a root component of type library' do
        expect(json[:type]).to eql('library')
      end
    end

    it 'should generate a correct component name' do
      expect(xml.at('/component/name')).not_to be_nil
      expect(xml.at('/component/name').text).to eql(pod.name)
    end

    context 'for JSON' do
      it 'should generate a correct component name' do
        expect(json[:name]).to eql(pod.name)
      end
    end

    it 'should generate a correct component version' do
      expect(xml.at('/component/version')).not_to be_nil
      expect(xml.at('/component/version').text).to eql(pod.version.to_s)
    end

    context 'for JSON' do
      it 'should generate a correct component version' do
        expect(json[:version]).to eql(pod.version.to_s)
      end
    end

    it 'should generate a correct component purl' do
      expect(xml.at('/component/purl')).not_to be_nil
      expect(xml.at('/component/purl').text).to eql(pod.purl)
    end
    context 'for JSON' do
      it 'should generate a correct component purl' do
        expect(json[:purl]).to eql(pod.purl)
      end
    end

    context 'when shortening to a limited string length' do
      it 'should truncate the purl to the right number of characters' do
        expect(shortXML.at('/component/purl')).not_to be_nil
        expect(shortXML.at('/component/purl').text).to eql('pkg:coc')
      end
    end

    context 'when not having an author' do
      it 'shouldn\'t generate a component author' do
        expect(xml.at('/component/author')).to be_nil
        expect(xml.at('/component/publisher')).to be_nil
      end
      context 'for JSON' do
        it 'shouldn\'t generate a component author' do
          expect(json[:author]).to be_nil
          expect(json[:publisher]).to be_nil
        end
      end
    end

    context 'when having an author' do
      let(:pod) do
        described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(author: author)
      end

      it 'should generate a correct component author' do
        expect(xml.at('/component/author')).not_to be_nil
        expect(xml.at('/component/author').text).to eql(pod.author)
        expect(xml.at('/component/publisher')).not_to be_nil
        expect(xml.at('/component/publisher').text).to eql(pod.author)
      end
      context 'for JSON' do
        it 'should generate a correct component author' do
          expect(json[:author]).to eql(pod.author)
          expect(json[:publisher]).to eql(pod.author)
        end
      end

      context 'when shortening to a limited string length' do
        it 'should truncate the author to the right number of characters' do
          expect(shortXML.at('/component/author')).not_to be_nil
          expect(shortXML.at('/component/author').text).to eql('Darth V')
          expect(shortXML.at('/component/publisher')).not_to be_nil
          expect(shortXML.at('/component/publisher').text).to eql('Darth V')
        end
        context 'for JSON' do
          it 'should truncate the author to the right number of characters' do
            expect(json_short[:author]).to eql('Darth V')
            expect(json_short[:publisher]).to eql('Darth V')
          end
        end
      end
    end

    context 'when not having a description' do
      it 'shouldn\'t generate a component description' do
        expect(xml.at('/component/description')).to be_nil
      end
      context 'for JSON' do
        it 'shouldn\'t generate a component description' do
          expect(json[:description]).to be_nil
        end
      end
    end

    context 'when having a description' do
      let(:pod) do
        described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(summary: summary)
      end

      it 'should generate a correct component description' do
        expect(xml.at('/component/description')).not_to be_nil
        expect(xml.at('/component/description').text).to eql(pod.description)
      end
      context 'for JSON' do
        it 'should generate a correct component description' do
          expect(json[:description]).to eql(pod.description)
        end
      end
    end

    context 'when not having a checksum' do
      let(:pod) { described_class.new(name: pod_name, version: pod_version) }

      it 'shouldn\'t generate a component hash' do
        expect(xml.at('/component/hashes')).to be_nil
      end
      context 'for JSON' do
        it 'shouldn\'t generate a component hash' do
          expect(json[:hashes]).to be_nil
        end
      end
    end

    context 'when having a checksum' do
      it 'should generate a correct component hash' do
        expect(xml.at('/component/hashes/hash')).not_to be_nil
        # CocoaPods always uses SHA-1
        expect(xml.at('/component/hashes/hash')['alg']).to eq(described_class::CHECKSUM_ALGORITHM)
        expect(xml.at('/component/hashes/hash').text).to eql(pod.checksum)
      end
      context 'for JSON' do
        it 'should generate a correct component hash' do
          expect(json[:hashes]).to eq([{ alg: described_class::CHECKSUM_ALGORITHM, content: pod.checksum }])
        end
      end
    end

    context 'when not having a license' do
      it 'shouldn\'t generate a license list' do
        expect(xml.at('/component/licenses')).to be_nil
      end
      context 'for JSON' do
        it 'shouldn\'t generate a license list' do
          expect(json[:licenses]).to be_nil
        end
      end
    end

    context 'when having a license' do
      let(:pod) do
        described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(license: 'MIT')
      end

      it 'should generate a child licenses node' do
        expect(xml.at('/component/licenses')).not_to be_nil
      end
      context 'for JSON' do
        it 'should generate a child licenses node' do
          expect(json[:licenses]).to eq([{ license: { id: 'MIT' } }])
        end
      end

      it 'should properly delegate license node generation' do
        license_generated_from_pod = xml.xpath('/component/licenses/license')[0]

        license = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          pod.license.add_to_bom(xml)
        end.to_xml).at('/license')

        expect(license_generated_from_pod).to be_equivalent_to(license)
      end
    end

    context 'when not having a homepage' do
      it 'shouldn\'t generate an external references list' do
        expect(xml.at('/component/externalReferences')).to be_nil
      end
      context 'for JSON' do
        it 'shouldn\'t generate an external references list' do
          expect(json[:externalReferences]).to be_nil
        end
      end
    end

    context 'when having a homepage' do
      let(:pod) do
        described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(homepage: homepage)
      end

      it 'should properly generate a component external references list' do
        expect(xml.at('/component/externalReferences')).not_to be_nil
        expect(xml.at('/component/externalReferences/reference')).not_to be_nil
        actual = xml.at('/component/externalReferences/reference')['type']
        expect(actual).to eq(described_class::HOMEPAGE_REFERENCE_TYPE)
        expect(xml.at('/component/externalReferences/reference/url')).not_to be_nil
        expect(xml.at('/component/externalReferences/reference/url').text).to eq(homepage)
      end
      context 'for JSON' do
        it 'should properly generate a component external references list' do
          expect(json[:externalReferences]).to eq([{ type: described_class::HOMEPAGE_REFERENCE_TYPE, url: homepage }])
        end
      end
    end
  end
end

RSpec.describe CycloneDX::CocoaPods::Pod::License do
  context 'when generating a license in a BOM' do
    context 'for known licenses' do
      let(:license) { described_class.new(identifier: described_class::SPDX_LICENSES.sample) }
      let(:xml) do
        Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          license.add_to_bom(xml)
        end.to_xml)
      end
      let(:json) do
        license.to_json_component
      end

      it 'should generate a root license element' do
        expect(xml.at('/license')).not_to be_nil
      end
      context 'for JSON' do
        it 'should generate a root license element' do
          expect(json[:license]).not_to be_nil
        end
      end

      it 'should generate a correct license identifier' do
        expect(xml.at('/license/id')).not_to be_nil
        expect(xml.at('/license/id').text).to eq(license.identifier)
        expect(xml.at('/license/name')).to be_nil
      end
      context 'for JSON' do
        it 'should generate a correct license identifier' do
          expect(json[:license][:id]).to eq(license.identifier)
          expect(json[:license][:name]).to be_nil
        end
      end

      it 'should not create text or url elements' do
        expect(xml.at('/license/text')).to be_nil
        expect(xml.at('/license/url')).to be_nil
      end
      context 'for JSON' do
        it 'should not create text or url elements' do
          expect(json[:license][:text]).to be_nil
          expect(json[:license][:url]).to be_nil
        end
      end

      context 'which includes text' do
        let(:license) do
          license_with_text = described_class.new(identifier: described_class::SPDX_LICENSES.sample)
          license_with_text.text = 'Copyright 2012\nPermission is granted to...'
          license_with_text
        end

        it 'should create text element' do
          expect(xml.at('/license/text')).not_to be_nil
          expect(xml.at('/license/text').text).to eq(license.text)
        end
        context 'for JSON' do
          it 'should create text element' do
            expect(json[:license][:text]).to eq({ content: license.text, contentType: 'text/plain' })
          end
        end
      end

      context 'which includes url' do
        let(:license) do
          license_with_url = described_class.new(identifier: described_class::SPDX_LICENSES.sample)
          license_with_url.url = 'https://opensource.org/licenses/MIT'
          license_with_url
        end

        it 'should create text element' do
          expect(xml.at('/license/url')).not_to be_nil
          expect(xml.at('/license/url').text).to eq(license.url)
        end
        context 'for JSON' do
          it 'should create text element' do
            expect(json[:license][:url]).to eq(license.url)
          end
        end
      end

      context 'for JSON' do
        it 'should create text element as an object when text is plain text' do
          license_with_text = described_class.new(identifier: described_class::SPDX_LICENSES.sample)
          license_with_text.text = 'Copyright 2022 Google'
          json = license_with_text.to_json_component
          expect(json[:license][:text]).to eq({ content: 'Copyright 2022 Google', contentType: 'text/plain' })
          expect(json[:license][:url]).to be_nil
        end

        it 'should use url field when text is a URL' do
          license_with_url_text = described_class.new(identifier: described_class::SPDX_LICENSES.sample)
          license_with_url_text.text = 'https://developers.google.com/terms/'
          json = license_with_url_text.to_json_component
          expect(json[:license][:url]).to eq('https://developers.google.com/terms/')
          expect(json[:license][:text]).to be_nil
        end
      end
    end
  end
end

RSpec.describe CycloneDX::CocoaPods::Component do
  context 'when generating a component in a BOM' do
    shared_examples 'component' do
      it 'should generate a root component element' do
        expect(xml.at('/component')).not_to be_nil
        expect(xml.at('/component')['type']).to eq(component.type)
        expect(xml.at('/component')['bom-ref']).not_to be_nil
      end

      it 'should generate proper component information' do
        expect(xml.at('/component/name')).not_to be_nil
        expect(xml.at('/component/name').text).to eq(component.name)
        expect(xml.at('/component/version')).not_to be_nil
        expect(xml.at('/component/version').text).to eq(component.version)
        expect(xml.at('/component')['bom-ref']).not_to be_nil
      end
    end

    context 'without a group and type application' do
      let(:component) { described_class.new(name: 'Application', version: '1.3.5', type: 'application') }
      let(:xml) do
        Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml| component.add_to_bom(xml) }.to_xml)
      end
      let(:json) do
        component.to_json_component
      end

      it_behaves_like 'component'

      it 'should not generate any group element' do
        expect(xml.at('/component/group')).to be_nil
        expect(xml.at('/component')['bom-ref']).to eq('pkg:generic/Application@1.3.5')
        expect(xml.at('/component/purl').text).to eq('pkg:generic/Application@1.3.5')
      end
      context 'for JSON' do
        it 'should not generate any group element' do
          expect(json[:group]).to be_nil
          expect(json[:'bom-ref']).to eq('pkg:generic/Application@1.3.5')
        end
      end
    end

    context 'without a group and type library' do
      let(:component) { described_class.new(name: 'Application', version: '1.3.5', type: 'library') }
      let(:xml) do
        Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml| component.add_to_bom(xml) }.to_xml)
      end

      it_behaves_like 'component'

      it 'should not generate any group element' do
        expect(xml.at('/component/group')).to be_nil
        expect(xml.at('/component')['bom-ref']).to eq('pkg:generic/Application@1.3.5')
        expect(xml.at('/component/purl').text).to eq('pkg:generic/Application@1.3.5')
      end
    end

    context 'without type cocoapods - a special case' do
      let(:component) { described_class.new(name: 'SampleProject', version: '1.0.0', type: 'cocoapods') }
      let(:xml) do
        Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml| component.add_to_bom(xml) }.to_xml)
      end

      it_behaves_like 'component'

      it 'should not generate any group element' do
        expect(xml.at('/component/group')).to be_nil
        expect(xml.at('/component')['bom-ref']).to eq('pkg:cocoapods/SampleProject@1.0.0')
        expect(xml.at('/component/purl').text).to eq('pkg:cocoapods/SampleProject@1.0.0')
      end
    end

    context 'with a group and type Application' do
      let(:component) do
        described_class.new(group: 'application-group', name: 'Application', version: '1.3.5', type: 'application')
      end
      let(:xml) do
        Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml| component.add_to_bom(xml) }.to_xml)
      end
      let(:json) do
        component.to_json_component
      end

      it_behaves_like 'component'

      it 'should generate a proper group element' do
        expect(xml.at('/component/group')).not_to be_nil
        expect(xml.at('/component/group').text).to eq(component.group)
        expect(xml.at('/component')['bom-ref']).to eq('pkg:generic/application-group/Application@1.3.5')
        expect(xml.at('/component/purl').text).to eq('pkg:generic/application-group/Application@1.3.5')
      end
      context 'for JSON' do
        it 'should generate a proper group element' do
          expect(json[:group]).to eq(component.group)
          expect(json[:'bom-ref']).to eq('pkg:generic/application-group/Application@1.3.5')
          expect(json[:purl]).to eq('pkg:generic/application-group/Application@1.3.5')
        end
      end
    end

    ## this test is just for completeness, the group is not used for libraries
    context 'with a group and type library' do
      let(:component) do
        described_class.new(group: 'application-group', name: 'Application', version: '1.3.5', type: 'library')
      end
      let(:xml) do
        Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml| component.add_to_bom(xml) }.to_xml)
      end
      let(:json) do
        component.to_json_component
      end

      it_behaves_like 'component'

      it 'should generate a proper group element' do
        expect(xml.at('/component/group')).not_to be_nil
        expect(xml.at('/component/group').text).to eq(component.group)
        expect(xml.at('/component')['bom-ref']).to eq('pkg:generic/application-group/Application@1.3.5')
        expect(xml.at('/component/purl').text).to eq('pkg:generic/application-group/Application@1.3.5')
      end
      context 'for JSON' do
        it 'should generate a proper group element' do
          expect(json[:group]).to eq(component.group)
          expect(json[:'bom-ref']).to eq('pkg:generic/application-group/Application@1.3.5')
        end
      end
    end

    context 'with a vcs' do
      let(:component) do
        described_class.new(group: 'application-group', name: 'Application', version: '1.3.5',
                            type: 'application', vcs: 'https://github.com/Alamofire/Alamofire.git')
      end
      let(:xml) do
        Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml| component.add_to_bom(xml) }.to_xml)
      end
      let(:json) do
        component.to_json_component
      end

      it_behaves_like 'component'

      it 'should generate a proper external references for vcs' do
        expect(xml.at('/component/group')).not_to be_nil
        expect(xml.at('/component/group').text).to eq(component.group)
        expect(xml.at('/component')['bom-ref']).to eq('pkg:generic/application-group/Application@1.3.5')
        expect(xml.at('/component/externalReferences/reference')['type']).to eq('vcs')
        expect(xml.at('/component/externalReferences/reference/url').text).to eq(component.vcs)
      end
      context 'for JSON' do
        it 'should generate a proper external references for vcs' do
          expect(json[:group]).to eq(component.group)
          expect(json[:'bom-ref']).to eq('pkg:generic/application-group/Application@1.3.5')
          expect(json[:externalReferences]).to eq([{ type: 'vcs', url: component.vcs }])
        end
      end
    end

    context 'with a build system' do
      let(:component) do
        described_class.new(group: 'application-group', name: 'Application', version: '1.3.5', type: 'application',
                            build_system: 'https://github.com/Alamofire/Alamofire/actions/runs/12012983790')
      end
      let(:xml) do
        Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml| component.add_to_bom(xml) }.to_xml)
      end
      let(:json) do
        component.to_json_component
      end

      it_behaves_like 'component'

      it 'should generate a proper external reference element for build-systems' do
        expect(xml.at('/component/group')).not_to be_nil
        expect(xml.at('/component/group').text).to eq(component.group)
        expect(xml.at('/component')['bom-ref']).to eq('pkg:generic/application-group/Application@1.3.5')
        expect(xml.at('/component/externalReferences/reference')['type']).to eq('build-system')
        expect(xml.at('/component/externalReferences/reference/url').text).to eq(component.build_system)
      end
      context 'for JSON' do
        it 'should generate a proper external reference element for build-systems' do
          expect(json[:group]).to eq(component.group)
          expect(json[:'bom-ref']).to eq('pkg:generic/application-group/Application@1.3.5')
          expect(json[:externalReferences]).to eq([{ type: 'build-system', url: component.build_system }])
        end
      end
    end
  end
end

RSpec.describe CycloneDX::CocoaPods::Manufacturer do
  context 'when generating a manufacturer in a BOM' do
    shared_examples 'manufacturer' do
      it 'should generate a root manufacturer element' do
        expect(xml.at('/manufacturer')).not_to be_nil
      end
      context 'for JSON' do
        it 'should generate a root manufacturer element' do
          expect(json).not_to be_nil
        end
      end

      it 'should generate proper manufacturer information' do
        expect(xml.at('/manufacturer/name')).not_to be_nil if manufacturer.name
        expect(xml.at('/manufacturer/name')&.text).to eq(manufacturer.name) if manufacturer.name
        expect(xml.at('/manufacturer/url')).not_to be_nil if manufacturer.url
        expect(xml.at('/manufacturer/url')&.text).to eq(manufacturer.url) if manufacturer.url
      end
      context 'for JSON' do
        it 'should generate proper manufacturer information' do
          expect(json[:name]).to eq(manufacturer.name) if manufacturer.name
          expect(json[:url]).to eq(manufacturer.url) if manufacturer.url
        end
      end
    end

    context 'without contact information' do
      let(:manufacturer) { described_class.new(name: 'ACME Corp', url: 'https://acme.example') }
      let(:xml) do
        Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml| manufacturer.add_to_bom(xml) }.to_xml)
      end
      let(:json) do
        manufacturer.to_json_manufacturer
      end
      it_behaves_like 'manufacturer'

      it 'should not generate any contact element' do
        expect(xml.at('/manufacturer/contact')).to be_nil
      end
      context 'for JSON' do
        it 'should not generate any contact element' do
          expect(json[:contact]).to be_nil
        end
      end
    end

    context 'with contact information' do
      let(:manufacturer) do
        described_class.new(
          name: 'ACME Corp',
          url: 'https://acme.example',
          contact_name: 'John Doe',
          email: 'john@acme.example',
          phone: '+1-555-123-4567'
        )
      end
      let(:xml) do
        Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml| manufacturer.add_to_bom(xml) }.to_xml)
      end
      let(:json) do
        manufacturer.to_json_manufacturer
      end

      it_behaves_like 'manufacturer'

      it 'should generate proper contact elements' do
        expect(xml.at('/manufacturer/contact')).not_to be_nil
        expect(xml.at('/manufacturer/contact/name').text).to eq(manufacturer.contact_name)
        expect(xml.at('/manufacturer/contact/email').text).to eq(manufacturer.email)
        expect(xml.at('/manufacturer/contact/phone').text).to eq(manufacturer.phone)
      end
      context 'for JSON' do
        it 'should generate proper contact elements' do
          expect(json[:contact][0][:name]).to eq(manufacturer.contact_name)
          expect(json[:contact][0][:email]).to eq(manufacturer.email)
          expect(json[:contact][0][:phone]).to eq(manufacturer.phone)
        end
      end
    end
  end
end

RSpec.describe CycloneDX::CocoaPods::BOMBuilder do
  context 'when generating a BOM' do
    # Important: these pods are NOT in alphabetical order; they will be sorted in output
    let(:pods) do
      {
        'Alamofire' => '5.6.2',
        'FirebaseAnalytics' => '7.10.0',
        'RxSwift' => '5.1.2',
        'Realm' => '5.5.1',
        'MSAL' => '1.2.1',
        'MSAL/app-lib' => '1.2.1'
      }.map do |name, version|
        pod = CycloneDX::CocoaPods::Pod.new(name: name, version: version)
        pod.populate(author: 'Chewbacca')
        pod
      end
    end
    # Important: these dependencies are NOT in alphabetical order; they will be sorted in output
    let(:dependencies) do
      {
        'pkg:cocoapods/Alamofire@5.6.2' => [],
        'pkg:cocoapods/MSAL@1.2.1' => ['pkg:cocoapods/MSAL@1.2.1#app-lib'],
        'pkg:cocoapods/FirebaseAnalytics@7.10.0' => [],
        'pkg:cocoapods/RxSwift@5.1.2' => [],
        'pkg:cocoapods/Realm@5.5.1' => []
      }
    end
    # Important: these expected components are sorted alphabetically
    let(:pod_result) do
      <<~XML
        <components>
          <component type="library" bom-ref="pkg:cocoapods/Alamofire@5.6.2">
            <author>Chewbacca</author>
            <publisher>Chewbacca</publisher>
            <name>Alamofire</name>
            <version>5.6.2</version>
            <purl>pkg:cocoapods/Alamofire@5.6.2</purl>
            <evidence>
              <identity>
                <field>purl</field>
                <confidence>0.6</confidence>
                <methods>
                  <method>
                    <technique>manifest-analysis</technique>
                    <confidence>0.6</confidence>
                    <value>sample_manifest.lock</value>
                  </method>
                </methods>
              </identity>
            </evidence>
          </component>
          <component type="library" bom-ref="pkg:cocoapods/FirebaseAnalytics@7.10.0">
            <author>Chewbacca</author>
            <publisher>Chewbacca</publisher>
            <name>FirebaseAnalytics</name>
            <version>7.10.0</version>
            <purl>pkg:cocoapods/FirebaseAnalytics@7.10.0</purl>
            <evidence>
              <identity>
                <field>purl</field>
                <confidence>0.6</confidence>
                <methods>
                  <method>
                    <technique>manifest-analysis</technique>
                    <confidence>0.6</confidence>
                    <value>sample_manifest.lock</value>
                  </method>
                </methods>
              </identity>
            </evidence>
          </component>
          <component type="library" bom-ref="pkg:cocoapods/MSAL@1.2.1">
            <author>Chewbacca</author>
            <publisher>Chewbacca</publisher>
            <name>MSAL</name>
            <version>1.2.1</version>
            <purl>pkg:cocoapods/MSAL@1.2.1</purl>
            <evidence>
              <identity>
                <field>purl</field>
                <confidence>0.6</confidence>
                <methods>
                  <method>
                    <technique>manifest-analysis</technique>
                    <confidence>0.6</confidence>
                    <value>sample_manifest.lock</value>
                  </method>
                </methods>
              </identity>
            </evidence>
          </component>
          <component type="library" bom-ref="pkg:cocoapods/MSAL@1.2.1#app-lib">
            <author>Chewbacca</author>
            <publisher>Chewbacca</publisher>
            <name>MSAL/app-lib</name>
            <version>1.2.1</version>
            <purl>pkg:cocoapods/MSAL@1.2.1#app-lib</purl>
            <evidence>
              <identity>
                <field>purl</field>
                <confidence>0.6</confidence>
                <methods>
                  <method>
                    <technique>manifest-analysis</technique>
                    <confidence>0.6</confidence>
                    <value>sample_manifest.lock</value>
                  </method>
                </methods>
              </identity>
            </evidence>
          </component>
          <component type="library" bom-ref="pkg:cocoapods/Realm@5.5.1">
            <author>Chewbacca</author>
            <publisher>Chewbacca</publisher>
            <name>Realm</name>
            <version>5.5.1</version>
            <purl>pkg:cocoapods/Realm@5.5.1</purl>
            <evidence>
              <identity>
                <field>purl</field>
                <confidence>0.6</confidence>
                <methods>
                  <method>
                    <technique>manifest-analysis</technique>
                    <confidence>0.6</confidence>
                    <value>sample_manifest.lock</value>
                  </method>
                </methods>
              </identity>
            </evidence>
          </component>
          <component type="library" bom-ref="pkg:cocoapods/RxSwift@5.1.2">
            <author>Chewbacca</author>
            <publisher>Chewbacca</publisher>
            <name>RxSwift</name>
            <version>5.1.2</version>
            <purl>pkg:cocoapods/RxSwift@5.1.2</purl>
            <evidence>
              <identity>
                <field>purl</field>
                <confidence>0.6</confidence>
                <methods>
                  <method>
                    <technique>manifest-analysis</technique>
                    <confidence>0.6</confidence>
                    <value>sample_manifest.lock</value>
                  </method>
                </methods>
              </identity>
            </evidence>
          </component>
        </components>
      XML
    end
    # Important: these expected components are sorted alphabetically
    let(:short_pod_results) do
      <<~XML
        <components>
          <component type="library" bom-ref="pkg:cocoapods/Alamofire@5.6.2">
            <author>Chewba</author>
            <publisher>Chewba</publisher>
            <name>Alamofire</name>
            <version>5.6.2</version>
            <purl>pkg:co</purl>
            <evidence>
              <identity>
                <field>purl</field>
                <confidence>0.6</confidence>
                <methods>
                  <method>
                    <technique>manifest-analysis</technique>
                    <confidence>0.6</confidence>
                    <value>sample_manifest.lock</value>
                  </method>
                </methods>
              </identity>
            </evidence>
          </component>
          <component type="library" bom-ref="pkg:cocoapods/FirebaseAnalytics@7.10.0">
            <author>Chewba</author>
            <publisher>Chewba</publisher>
            <name>FirebaseAnalytics</name>
            <version>7.10.0</version>
            <purl>pkg:co</purl>
            <evidence>
              <identity>
                <field>purl</field>
                <confidence>0.6</confidence>
                <methods>
                  <method>
                    <technique>manifest-analysis</technique>
                    <confidence>0.6</confidence>
                    <value>sample_manifest.lock</value>
                  </method>
                </methods>
              </identity>
            </evidence>
          </component>
          <component type="library" bom-ref="pkg:cocoapods/MSAL@1.2.1">
            <author>Chewba</author>
            <publisher>Chewba</publisher>
            <name>MSAL</name>
            <version>1.2.1</version>
            <purl>pkg:co</purl>
            <evidence>
              <identity>
                <field>purl</field>
                <confidence>0.6</confidence>
                <methods>
                  <method>
                    <technique>manifest-analysis</technique>
                    <confidence>0.6</confidence>
                    <value>sample_manifest.lock</value>
                  </method>
                </methods>
              </identity>
            </evidence>
          </component>
          <component type="library" bom-ref="pkg:cocoapods/MSAL@1.2.1#app-lib">
            <author>Chewba</author>
            <publisher>Chewba</publisher>
            <name>MSAL/app-lib</name>
            <version>1.2.1</version>
            <purl>pkg:co</purl>
            <evidence>
              <identity>
                <field>purl</field>
                <confidence>0.6</confidence>
                <methods>
                  <method>
                    <technique>manifest-analysis</technique>
                    <confidence>0.6</confidence>
                    <value>sample_manifest.lock</value>
                  </method>
                </methods>
              </identity>
            </evidence>
          </component>
          <component type="library" bom-ref="pkg:cocoapods/Realm@5.5.1">
            <author>Chewba</author>
            <publisher>Chewba</publisher>
            <name>Realm</name>
            <version>5.5.1</version>
            <purl>pkg:co</purl>
            <evidence>
              <identity>
                <field>purl</field>
                <confidence>0.6</confidence>
                <methods>
                  <method>
                    <technique>manifest-analysis</technique>
                    <confidence>0.6</confidence>
                    <value>sample_manifest.lock</value>
                  </method>
                </methods>
              </identity>
            </evidence>
          </component>
          <component type="library" bom-ref="pkg:cocoapods/RxSwift@5.1.2">
            <author>Chewba</author>
            <publisher>Chewba</publisher>
            <name>RxSwift</name>
            <version>5.1.2</version>
            <purl>pkg:co</purl>
            <evidence>
              <identity>
                <field>purl</field>
                <confidence>0.6</confidence>
                <methods>
                  <method>
                    <technique>manifest-analysis</technique>
                    <confidence>0.6</confidence>
                    <value>sample_manifest.lock</value>
                  </method>
                </methods>
              </identity>
            </evidence>
          </component>
        </components>
      XML
    end

    shared_examples 'bom_generator' do
      context 'with an incorrect version' do
        it 'should raise for non integer versions' do
          expect { bom_builder.bom(version: 'foo') }.to raise_error(ArgumentError)
        end

        it 'should raise for negative versions' do
          expect { bom_builder.bom(version: -1) }.to raise_error(ArgumentError)
        end
      end

      context 'with an incorrect trim_strings_length' do
        it 'should raise for non integer trim_strings_length' do
          expect { bom_builder.bom(version: 1, trim_strings_length: 'foo') }.to raise_error(ArgumentError)
        end

        it 'should raise for negative trim_strings_length' do
          expect { bom_builder.bom(version: 1, trim_strings_length: -1) }.to raise_error(ArgumentError)
        end
      end

      context 'with a missing version' do
        it 'should use 1 as default version value' do
          expect(Nokogiri::XML(bom_builder.bom).root['version']).to eq('1')
        end

        context 'twice' do
          it 'should generate different serial numbers' do
            original_serial_number = Nokogiri::XML(bom_builder.bom).root['serialNumber']
            expect(Nokogiri::XML(bom_builder.bom).root['serialNumber']).not_to eq(original_serial_number)
          end
        end
      end

      context 'with a valid version' do
        let(:version) { Random.rand(1..100) }
        let(:xml) { Nokogiri::XML(bom_builder.bom(version: version)) }

        it 'should be able to use integer-ish versions' do
          expect(Nokogiri::XML(bom_builder.bom(version: version.to_s)).root['version']).to eq(version.to_s)
        end

        context 'twice' do
          it 'should generate different serial numbers' do
            first_serial_number = Nokogiri::XML(bom_builder.bom(version: version)).root['serialNumber']
            second_serial_number = Nokogiri::XML(bom_builder.bom(version: version)).root['serialNumber']
            expect(second_serial_number).not_to eq(first_serial_number)
          end
        end

        it 'should use the provided version' do
          expect(xml.root['version']).to eq(version.to_s)
        end

        it 'should generate a proper root node' do
          root = xml.root

          expect(root.name).to eq('bom')
          expect(root.namespace.href).to eq(described_class::NAMESPACE)
          expect(root['version']).to eq(version.to_s)
          expect(root['serialNumber']).to match(/urn:uuid:.*/)
        end

        it 'should include a timestamp in the metadata' do
          expect(xml.at('bom/metadata/timestamp')).not_to be_nil
        end

        it 'should generate tools metadata' do
          expect(xml.at('bom/metadata/tools')).not_to be_nil

          # Only tool should be cyclonedx-cocoapods
          expect(xml.css('bom/metadata/tools/components/component/group').text).to eq('CycloneDX')
          expect(xml.css('bom/metadata/tools/components/component/name').text).to eq('cyclonedx-cocoapods')
          expect(xml.css('bom/metadata/tools/components/component/version').text).to eq(CycloneDX::CocoaPods::VERSION)
        end

        it 'should generate component metadata when a component is available' do
          if bom_builder.component
            component_metadata = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
              xml.metadata(xmlns: described_class::NAMESPACE) do
                component.add_to_bom(xml)
              end
            end.to_xml).at('metadata/component')

            expect(xml.at('bom/metadata/component')).not_to be_nil
            expect(xml.at('bom/metadata/component')).to be_equivalent_to(component_metadata)
          else
            expect(xml.at('bom/metadata/component')).to be_nil
          end
        end

        it 'should generate a child components node' do
          expect(xml.at('bom/components')).not_to be_nil
        end

        it 'should properly delegate component node generation to pods' do
          actual = xml.at('bom/components').to_xml

          expected = Nokogiri::XML pod_result
          expected = expected.root.to_xml

          expect(actual).to be_equivalent_to(expected).respecting_element_order
        end

        it 'should generate a child dependencies node' do
          expect(xml.at('bom/dependencies')).not_to be_nil
        end

        it 'should properly set dependencies node' do
          actual = xml.at('bom/dependencies').to_xml

          expected = Nokogiri::XML dependencies_result
          expected = expected.root.to_xml

          expect(actual).to be_equivalent_to(expected).respecting_element_order
        end

        context 'when asked to shorten strings' do
          let(:shortXML) { Nokogiri::XML(bom_builder.bom(version: version, trim_strings_length: 6)) }

          it 'should properly trim the author, publisher, and purl' do
            actual = shortXML.at('bom/components').to_xml

            expected = Nokogiri::XML short_pod_results
            expected = expected.root.to_xml

            expect(actual).to be_equivalent_to(expected).respecting_element_order
          end
        end
      end
    end

    context 'without a component' do
      let(:bom_builder) { described_class.new(pods: pods, manifest_path: 'sample_manifest.lock') }
      let(:dependencies_result) { '<dependencies/>' }

      it_behaves_like 'bom_generator'
    end

    context 'with a component' do
      let(:component) do
        CycloneDX::CocoaPods::Component.new(name: 'Application', version: '1.3.5', type: 'application')
      end
      let(:bom_builder) do
        described_class.new(component: component,
                            manifest_path: 'sample_manifest.lock',
                            pods: pods,
                            dependencies: dependencies)
      end
      # Important: these expected dependencies are sorted alphabetically
      let(:dependencies_result) do
        <<~XML
          <dependencies>
            <dependency ref="pkg:cocoapods/Alamofire@5.6.2"/>
            <dependency ref="pkg:cocoapods/FirebaseAnalytics@7.10.0"/>
            <dependency ref="pkg:cocoapods/MSAL@1.2.1">
              <dependency ref="pkg:cocoapods/MSAL@1.2.1#app-lib"/>
            </dependency>
            <dependency ref="pkg:cocoapods/Realm@5.5.1"/>
            <dependency ref="pkg:cocoapods/RxSwift@5.1.2"/>
          </dependencies>
        XML
      end

      it_behaves_like 'bom_generator'
    end
  end

  context 'when generating a JSON BOM' do
    let(:pods) do
      {
        'Alamofire' => '5.6.2',
        'FirebaseAnalytics' => '7.10.0',
        'RxSwift' => '5.1.2',
        'Realm' => '5.5.1',
        'MSAL' => '1.2.1',
        'MSAL/app-lib' => '1.2.1'
      }.map do |name, version|
        pod = CycloneDX::CocoaPods::Pod.new(name: name, version: version)
        pod.populate(author: 'Chewbacca')
        pod
      end
    end
    let(:bom_builder) { described_class.new(pods: pods, manifest_path: 'sample_manifest.lock') }
    let(:version) { Random.rand(1..100) }
    let(:bom_json) { JSON.parse(bom_builder.bom(version: version, format: :json), symbolize_names: true) }

    it 'should generate proper root level attributes' do
      expect(bom_json[:bomFormat]).to eq('CycloneDX')
      expect(bom_json[:specVersion]).to eq('1.6')
      expect(bom_json[:version]).to eq(version.to_i)
      expect(bom_json[:serialNumber]).to match(/urn:uuid:.*/)
    end

    it 'should include metadata with timestamp and tools' do
      expect(bom_json[:metadata][:timestamp]).not_to be_nil
      expect(bom_json[:metadata][:tools][:components][0][:group]).to eq('CycloneDX')
      expect(bom_json[:metadata][:tools][:components][0][:name]).to eq('cyclonedx-cocoapods')
      expect(bom_json[:metadata][:tools][:components][0][:version]).to eq(CycloneDX::CocoaPods::VERSION)
    end

    it 'should generate components in alphabetical order' do
      component_purls = bom_json[:components].map { |c| c[:purl] }
      expect(component_purls).to eq(component_purls.sort)
    end

    it 'should properly generate pod components' do
      expect(bom_json[:components].length).to eq(pods.length)
      expect(bom_json[:components].first).to include(
        type: 'library',
        name: 'Alamofire',
        version: '5.6.2',
        author: 'Chewbacca',
        publisher: 'Chewbacca',
        purl: 'pkg:cocoapods/Alamofire@5.6.2'
      )
    end

    context 'when asked to shorten strings' do
      let(:short_json) do
        JSON.parse(
          bom_builder.bom(version: version, format: :json, trim_strings_length: 6),
          symbolize_names: true
        )
      end

      it 'should properly trim the author, publisher, and purl' do
        expect(short_json[:components].first).to include(
          author: 'Chewba',
          publisher: 'Chewba',
          purl: 'pkg:cocoapods/Alamofire@5.6.2'
        )
      end
    end

    context 'with dependencies' do
      let(:component) do
        CycloneDX::CocoaPods::Component.new(
          name: 'Application',
          version: '1.3.5',
          type: 'application'
        )
      end
      let(:dependencies) do
        {
          'pkg:cocoapods/Alamofire@5.6.2' => [],
          'pkg:cocoapods/MSAL@1.2.1' => ['pkg:cocoapods/MSAL@1.2.1#app-lib'],
          'pkg:cocoapods/FirebaseAnalytics@7.10.0' => [],
          'pkg:cocoapods/RxSwift@5.1.2' => [],
          'pkg:cocoapods/Realm@5.5.1' => []
        }
      end
      let(:bom_builder) do
        described_class.new(
          component: component,
          manifest_path: 'sample_manifest.lock',
          pods: pods,
          dependencies: dependencies
        )
      end

      it 'should generate dependencies in alphabetical order' do
        dependency_refs = bom_json[:dependencies].map { |d| d[:ref] }
        expect(dependency_refs).to eq(dependency_refs.sort)
      end

      it 'should properly generate nested dependencies' do
        msal_dependency = bom_json[:dependencies].find { |d| d[:ref] == 'pkg:cocoapods/MSAL@1.2.1' }
        expect(msal_dependency[:dependsOn]).to eq(['pkg:cocoapods/MSAL@1.2.1#app-lib'])
      end
    end
  end
end
