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

RSpec.describe CycloneDX::CocoaPods::Pod do
  let(:pod_name) { 'Alamofire' }
  let(:pod_version) { '5.4.2' }
  let(:checksum) { '9a8ccc3a24b87624f4b40883adab3d98a9fdc00d' }
  let(:author) { 'Darth Vader' }
  let(:summary) { 'Elegant HTTP Networking in Swift' }
  let(:homepage) { 'https://github.com/Alamofire/Alamofire' }

  let(:pod) { described_class.new(name: pod_name, version: pod_version, checksum: checksum) }
  let(:xml) {
    Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      pod.add_to_bom(xml)
    end.to_xml)
  }

  context 'when generating a pod component in a BOM' do
    it 'should generate a root component of type library' do
      expect(xml.at('/component')).not_to be_nil
      expect(xml.at('/component')['type']).to eql('library')
    end

    it 'should generate a correct component name' do
      expect(xml.at('/component/name')).not_to be_nil
      expect(xml.at('/component/name').text).to eql(pod.name)
    end

    it 'should generate a correct component version' do
      expect(xml.at('/component/version')).not_to be_nil
      expect(xml.at('/component/version').text).to eql(pod.version.to_s)
    end

    it 'should generate a correct component purl' do
      expect(xml.at('/component/purl')).not_to be_nil
      expect(xml.at('/component/purl').text).to eql(pod.purl)
    end

    context 'when not having an author' do
      it 'shouldn\'t generate a component author' do
        expect(xml.at('/component/author')).to be_nil
        expect(xml.at('/component/publisher')).to be_nil
      end
    end

    context 'when having an author' do
      let(:pod) { described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(author: author) }

      it 'should generate a correct component author' do
        expect(xml.at('/component/author')).not_to be_nil
        expect(xml.at('/component/author').text).to eql(pod.author)
        expect(xml.at('/component/publisher')).not_to be_nil
        expect(xml.at('/component/publisher').text).to eql(pod.author)
      end
    end

    context 'when not having a description' do
      it 'shouldn\'t generate a component description' do
        expect(xml.at('/component/description')).to be_nil
      end
    end

    context 'when having a description' do
      let(:pod) { described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(summary: summary) }

      it 'should generate a correct component description' do
        expect(xml.at('/component/description')).not_to be_nil
        expect(xml.at('/component/description').text).to eql(pod.description)
      end
    end

    context 'when not having a checksum' do
      let(:pod) { described_class.new(name: pod_name, version: pod_version) }

      it 'shouldn''t generate a component hash' do
        expect(xml.at('/component/hashes')).to be_nil
      end
    end

    context 'when having a checksum' do
      it 'should generate a correct component hash' do
        expect(xml.at('/component/hashes/hash')).not_to be_nil
        expect(xml.at('/component/hashes/hash')['alg']).to eq(described_class::CHECKSUM_ALGORITHM)  # CocoaPods always uses SHA-1
        expect(xml.at('/component/hashes/hash').text).to eql(pod.checksum)
      end
    end

    context 'when not having a license' do
      it 'shouldn''t generate a license list' do
        expect(xml.at('/component/licenses')).to be_nil
      end
    end

    context 'when having a license' do
      let(:pod) { described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(license: 'MIT') }

      it 'should generate a child licenses node' do
        expect(xml.at('/component/licenses')).not_to be_nil
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
    end

    context 'when having a homepage' do
      let(:pod) { described_class.new(name: pod_name, version: pod_version, checksum: checksum).populate(homepage: homepage) }

      it 'should properly generate a component external references list' do
        expect(xml.at('/component/externalReferences')).not_to be_nil
        expect(xml.at('/component/externalReferences/reference')).not_to be_nil
        expect(xml.at('/component/externalReferences/reference')['type']).to eq(described_class::HOMEPAGE_REFERENCE_TYPE)
        expect(xml.at('/component/externalReferences/reference/url')).not_to be_nil
        expect(xml.at('/component/externalReferences/reference/url').text).to eq(homepage)
      end
    end
  end
end


RSpec.describe CycloneDX::CocoaPods::Pod::License do
  context 'when generating a license in a BOM' do
    context 'for known licenses' do
      let(:license) { described_class.new(identifier: described_class::SPDX_LICENSES.sample) }
      let(:xml) {
        Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          license.add_to_bom(xml)
        end.to_xml)
      }

      it 'should generate a root license element' do
        expect(xml.at('/license')).not_to be_nil
      end

      it 'should generate a correct license identifier' do
        expect(xml.at('/license/id')).not_to be_nil
        expect(xml.at('/license/id').text).to eq(license.identifier)
        expect(xml.at('/license/name')).to be_nil
      end

      it 'should not create text or url elements' do
        expect(xml.at('/license/text')).to be_nil
        expect(xml.at('/license/url')).to be_nil
      end

      context 'which includes text' do
        let(:license) {
          license_with_text = described_class.new(identifier: described_class::SPDX_LICENSES.sample)
          license_with_text.text = "Copyright 2012\nPermission is granted to..."
          license_with_text
        }

        it 'should create text element' do
          expect(xml.at('/license/text')).not_to be_nil
          expect(xml.at('/license/text').text).to eq(license.text)
        end
      end

      context 'which includes url' do
        let(:license) {
          license_with_url = described_class.new(identifier: described_class::SPDX_LICENSES.sample)
          license_with_url.url = "https://opensource.org/licenses/MIT"
          license_with_url
        }

        it 'should create text element' do
          expect(xml.at('/license/url')).not_to be_nil
          expect(xml.at('/license/url').text).to eq(license.url)
        end
      end
    end
  end
end


RSpec.describe CycloneDX::CocoaPods::Component do
  context 'when generating a component in a BOM' do
    shared_examples "component" do
      it 'should generate a root component element' do
        expect(xml.at('/component')).not_to be_nil
        expect(xml.at('/component')['type']).to eq(component.type)
      end

      it 'should generate proper component information' do
        expect(xml.at('/component/name')).not_to be_nil
        expect(xml.at('/component/name').text).to eq(component.name)
        expect(xml.at('/component/version')).not_to be_nil
        expect(xml.at('/component/version').text).to eq(component.version)
      end
    end

    context 'without a group' do
      let(:component) { described_class.new(name: 'Application', version: '1.3.5', type: 'application') }
      let(:xml) { Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml| component.add_to_bom(xml) }.to_xml) }

      it_behaves_like "component"

      it 'should not generate any group element' do
        expect(xml.at('/component/group')).to be_nil
      end
    end

    context 'with a group' do
      let(:component) { described_class.new(group: 'application-group', name: 'Application', version: '1.3.5', type: 'application') }
      let(:xml) { Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml| component.add_to_bom(xml) }.to_xml) }

      it_behaves_like "component"

      it 'should generate a proper group element' do
        expect(xml.at('/component/group')).not_to be_nil
        expect(xml.at('/component/group').text).to eq(component.group)
      end
    end
  end
end

RSpec.describe CycloneDX::CocoaPods::BOMBuilder do
  context 'when generating a BOM' do
    let(:pods)  do
      {
        'Alamofire' => '5.6.2',
        'FirebaseAnalytics' => '7.10.0',
        'RxSwift' => '5.1.2',
        'Realm' => '5.5.1',
        'MSAL' => '1.2.1',
        'MSAL/app-lib' => '1.2.1'
      }.map { |name, version| CycloneDX::CocoaPods::Pod.new(name: name, version: version) }
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

    shared_examples "bom_generator" do
      context 'with an incorrect version' do
        it 'should raise for non integer versions' do
          expect { bom_builder.bom(version: 'foo') }.to raise_error(ArgumentError)
        end

        it 'should raise for negative versions' do
          expect { bom_builder.bom(version: -1) }.to raise_error(ArgumentError)
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
        let(:version) { Random.rand(100) + 1 }
        let(:xml) { Nokogiri::XML(bom_builder.bom(version: version)) }

        it 'should be able to use integer-ish versions' do
          expect(Nokogiri::XML(bom_builder.bom(version: version.to_s)).root['version']).to eq(version.to_s)
        end

        context 'twice' do
          it 'should generate different serial numbers' do
            original_serial_number = Nokogiri::XML(bom_builder.bom(version: version)).root['serialNumber']
            expect(Nokogiri::XML(bom_builder.bom(version: version)).root['serialNumber']).not_to eq(original_serial_number)
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
          expect(xml.css('bom/metadata/tools/tool/vendor').text).to eq('CycloneDX')
          expect(xml.css('bom/metadata/tools/tool/name').text).to eq('cyclonedx-cocoapods')
          expect(xml.css('bom/metadata/tools/tool/version').text).to eq(CycloneDX::CocoaPods::VERSION)
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
          components_generated_from_bom_builder = xml.at('bom/components')

          components = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml.components(xmlns: described_class::NAMESPACE) do
              bom_builder.pods.each { |pod| pod.add_to_bom(xml) }
            end
          end.to_xml).at('components')

          expect(components_generated_from_bom_builder).to be_equivalent_to(components)
        end

        it 'should generate a child dependencies node' do
          expect(xml.at('bom/dependencies')).not_to be_nil
        end

        it 'shoudl properly set dependencies node' do
          dependencies_generated_from_bom_builder = xml.at('bom/dependencies')

          dependencies = Nokogiri::XML dependencies_result

          expect(dependencies_generated_from_bom_builder.to_xml).to be_equivalent_to(dependencies.root.to_xml)
        end
      end
    end

    context 'without a component' do
      let(:bom_builder) { described_class.new(pods: pods) }
      let(:dependencies_result) { '<dependencies/>' }

      it_behaves_like "bom_generator"
    end

    context 'with a component' do
      let(:component) { CycloneDX::CocoaPods::Component.new(name: 'Application', version: '1.3.5', type: 'application') }
      let(:bom_builder) { described_class.new(component: component, pods: pods, dependencies: dependencies) }
      let(:dependencies_result) do
        '<dependencies>
                                    <dependency ref="pkg:cocoapods/Alamofire@5.6.2"/>
                                    <dependency ref="pkg:cocoapods/MSAL@1.2.1">
                                      <dependency ref="pkg:cocoapods/MSAL@1.2.1#app-lib"/>
                                    </dependency>
                                    <dependency ref="pkg:cocoapods/FirebaseAnalytics@7.10.0"/>
                                    <dependency ref="pkg:cocoapods/RxSwift@5.1.2"/>
                                    <dependency ref="pkg:cocoapods/Realm@5.5.1"/>
                                  </dependencies>'
      end

      it_behaves_like "bom_generator"
    end
  end
end
