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

require 'rspec'
require 'cyclonedx/cocoapods/pod'
require 'cyclonedx/cocoapods/source'

RSpec.describe CycloneDX::CocoaPods::Pod do
  context 'when creating new pods' do
    context 'with a nil name' do
      it 'should raise an error' do
        expect { described_class.new(name: nil, version: '1.3.5') }.to raise_error(ArgumentError)
      end
    end

    context 'with an empty name' do
      it 'should raise an error' do
        expect { described_class.new(name: '  ', version: '1.3.5') }.to raise_error(ArgumentError)
      end
    end

    context 'with an invalid name' do
      let(:invalid_pod_names) { ['NoSpaces AllowedInsideName', ' NoSpacesAllowedOutsideName  ', 'No+SignAllowed', '.Can''tStartWithDot'] }
      it 'should raise an error' do
        invalid_pod_names.each { |pod_name|
          expect { described_class.new(name: pod_name, version: '1.3.5') }.to raise_error(ArgumentError)
        }
      end
    end

    context 'with a valid name' do
      let(:valid_pod_names) { %w[Alamofire FirebaseAnalytics R.swift Sentry Dèja%Vú Sentry/Core GoogleUtilities/NSData+zlib] }
      let(:valid_pod_root_names) { %w[Alamofire FirebaseAnalytics R.swift Sentry Dèja%Vú Sentry GoogleUtilities] }

      context 'and an invalid version' do
        it 'should raise an error' do
          expect { described_class.new(name: valid_pod_names[0], version: 'this.is-not_A_version') }.to raise_error(ArgumentError)
        end
      end

      context 'and a valid version' do
        let(:valid_versions) { %w[5.0 6.8.3 2.2.0-alpha.372] }
        let(:valid_pod_names_and_versions) { valid_pod_names.product(valid_versions) }
        let(:valid_pod_root_names_and_versions) { valid_pod_root_names.product(valid_versions) }
        let(:base_purls) { %w[
          pkg:cocoapods/Alamofire@5.0 pkg:cocoapods/Alamofire@6.8.3 pkg:cocoapods/Alamofire@2.2.0-alpha.372
          pkg:cocoapods/FirebaseAnalytics@5.0 pkg:cocoapods/FirebaseAnalytics@6.8.3 pkg:cocoapods/FirebaseAnalytics@2.2.0-alpha.372
          pkg:cocoapods/R.swift@5.0 pkg:cocoapods/R.swift@6.8.3 pkg:cocoapods/R.swift@2.2.0-alpha.372
          pkg:cocoapods/Sentry@5.0 pkg:cocoapods/Sentry@6.8.3 pkg:cocoapods/Sentry@2.2.0-alpha.372
          pkg:cocoapods/D%C3%A8ja%25V%C3%BA@5.0 pkg:cocoapods/D%C3%A8ja%25V%C3%BA@6.8.3 pkg:cocoapods/D%C3%A8ja%25V%C3%BA@2.2.0-alpha.372
          pkg:cocoapods/Sentry@5.0#Core pkg:cocoapods/Sentry@6.8.3#Core pkg:cocoapods/Sentry@2.2.0-alpha.372#Core
          pkg:cocoapods/GoogleUtilities@5.0#NSData%2Bzlib pkg:cocoapods/GoogleUtilities@6.8.3#NSData%2Bzlib pkg:cocoapods/GoogleUtilities@2.2.0-alpha.372#NSData%2Bzlib
        ] }

        shared_examples "valid_pod" do
          it 'should properly build the pod' do
            expect(valid_pods.map(&:name)).to eq(valid_pod_names_and_versions.map { |name, _| name })
            expect(valid_pods.map(&:version)).to eq(valid_pod_names_and_versions.map { |_, version| version })
            expect(valid_pods.map(&:checksum)).to eq(valid_pod_names_and_versions.map { checksum })
          end

          it 'should properly compute the root name' do
            expect(valid_pods.map(&:root_name)).to eq(valid_pod_root_names_and_versions.map { |name, _| name })
          end

          it 'should return a proper purl' do
            valid_pods.map(&:purl).zip(expected_purls).each do |pod_purl, expected_purl|
              expect(pod_purl).to eq(expected_purl)
            end
          end
        end

        shared_examples "pod_with_checksum" do
          context 'without checksum' do
            let(:checksum) { nil }
            let(:valid_pods) { valid_pod_names_and_versions.map { |name, version| described_class.new(name: name, version: version, source: source) } }
            it_behaves_like "valid_pod"
          end

          context 'with a valid checksum' do
            let(:checksum) { '9a8ccc3a24b87624f4b40883adab3d98a9fdc00d' }
            let(:valid_pods) { valid_pod_names_and_versions.map { |name, version| described_class.new(name: name, version: version, source: source, checksum: checksum) } }
            it_behaves_like "valid_pod"
          end

          context 'with an invalid checksum' do
            it 'should raise an error' do
              expect {
                described_class.new(name: valid_pod_names.sample, version: valid_versions.sample, checksum: 'not-a-valid-checksum')
              }.to raise_error(ArgumentError)
            end
          end
        end

        context 'without source' do
          let(:source) { nil }
          let(:expected_purls) { base_purls }
          it_behaves_like "pod_with_checksum"
        end

        context 'with source' do
          context 'from a repository' do
            context 'from the legacy repository' do
              let(:source) { CycloneDX::CocoaPods::Source::CocoaPodsRepository.new(url: 'https://github.com/CocoaPods/Specs.git') }
              let(:expected_purls) { base_purls }
              it_behaves_like "pod_with_checksum"
            end

            context 'from the CDN repository' do
              let(:source) { CycloneDX::CocoaPods::Source::CocoaPodsRepository.new(url: 'trunk') }
              let(:expected_purls) { base_purls }
              it_behaves_like "pod_with_checksum"
            end

            context 'from an alternative repository' do
              let(:source) { CycloneDX::CocoaPods::Source::CocoaPodsRepository.new(url: 'https://dl.cloudsmith.io/public/owner/repository/cocoapods/index.git') }
              let(:expected_purls) { base_purls.map { |purl| purl.insert(purl.index('#') || -1, "?repository_url=#{CGI.escape(source.url)}" ) } }
              it_behaves_like "pod_with_checksum"
            end
          end

          context 'from a git repository' do
            context 'with just a URL' do
              let(:source) { CycloneDX::CocoaPods::Source::GitRepository.new(url: 'https://github.com/gowalla/AFNetworking.git') }
              let(:expected_purls) { base_purls.map { |purl| purl.insert(purl.index('#') || -1, "?vcs_url=#{CGI.escape(source.url)}" ) } }
              it_behaves_like "pod_with_checksum"
            end

            context 'with a tag' do
              let(:source) { CycloneDX::CocoaPods::Source::GitRepository.new(url: 'https://github.com/gowalla/AFNetworking.git', type: :tag, label: '0.7.0') }
              let(:expected_purls) { base_purls.map { |purl| purl.insert(purl.index('#') || -1, "?vcs_url=#{CGI.escape(source.url)}%40#{CGI.escape(source.label)}" ) } }
              it_behaves_like "pod_with_checksum"
            end

            context 'with a branch' do
              let(:source) { CycloneDX::CocoaPods::Source::GitRepository.new(url: 'https://github.com/gowalla/AFNetworking.git', type: :branch, label: 'dev') }
              let(:expected_purls) { base_purls.map { |purl| purl.insert(purl.index('#') || -1, "?vcs_url=#{CGI.escape(source.url)}%40#{CGI.escape(source.label)}" ) } }
              it_behaves_like "pod_with_checksum"
            end

            context 'with a commit' do
              let(:source) { CycloneDX::CocoaPods::Source::GitRepository.new(url: 'https://github.com/gowalla/AFNetworking.git', type: :commit, label: '082f8319af') }
              let(:expected_purls) { base_purls.map { |purl| purl.insert(purl.index('#') || -1, "?vcs_url=#{CGI.escape(source.url)}%40#{CGI.escape(source.label)}" ) } }
              it_behaves_like "pod_with_checksum"
            end
          end

          context 'from local disk' do
            let(:source) { CycloneDX::CocoaPods::Source::LocalPod.new(path: '~/Documents/AFNetworking') }
            let(:expected_purls) { base_purls }
            it_behaves_like "pod_with_checksum"
          end

          context 'from other location' do
            let(:source) { CycloneDX::CocoaPods::Source::Podspec.new(url: 'https://example.com/JSONKit.podspec') }
            let(:expected_purls) { base_purls.map { |purl| purl.insert(purl.index('#') || -1, "?download_url=#{CGI.escape(source.url)}" ) } }
            it_behaves_like "pod_with_checksum"
          end
        end
      end
    end
  end

  context 'when populating a pod with attributes' do
    let(:author) { 'Darth Vader' }
    let(:author_list) { ['Darth Vader', 'Wookiee'] }
    let(:author_hash) { {
      'Darth Vader' => 'darthvader@darkside.com',
      'Wookiee' => 'wookiee@aggrrttaaggrrt.com'
    } }

    let(:summary) { 'Elegant HTTP Networking in Swift' }
    let(:description) { 'Alamofire provides an elegant and composable interface to HTTP network requests.' }
    let(:homepage) { 'https://github.com/Alamofire/Alamofire' }

    let(:pod) { described_class.new(name: 'Alamofire', version: '5.4.2') }

    it 'should return the pod itself' do
      expect(pod.populate(any_attribute: 'any value')).to be(pod)
    end

    it 'should leave pod name and version untouched' do
      original_name = pod.name
      original_version = pod.version

      pod.populate(author: author, summary: summary)

      expect(pod.name).to eq(original_name)
      expect(pod.version).to eq(original_version)
    end

    it 'should modify previous values of attributes' do
      pod.populate(author: author, summary: summary, homepage: homepage)
      expect(pod.author).to eq(author)
      expect(pod.description).to eq(summary)
      expect(pod.homepage).to eq(homepage)

      pod.populate(description: description)
      expect(pod.author).to be_nil
      expect(pod.description).to eq(description)
      expect(pod.homepage).to be_nil
    end

    it 'should accept both symbols and strings as attribute names' do
      pod.populate(author: 'Author as named parameter')
      expect(pod.author).to eq('Author as named parameter')

      pod.populate({ 'author' => 'Author as hash value with String key' })
      expect(pod.author).to eq('Author as hash value with String key')

      pod.populate({ author: 'Author as hash value with Symbol key' })
      expect(pod.author).to eq('Author as hash value with Symbol key')
    end

    context 'when the attributes hash contains an author' do
      context 'and a list of authors' do
        it 'should populate the pod''s author with the author from the attributes' do
          pod.populate(author: author, authors: author_list)
          expect(pod.author).to eq(author)
        end
      end

      context 'and a hash of authors' do
        it 'should populate the pod''s author with the author from the attributes' do
          pod.populate(author: author, authors: author_hash)
          expect(pod.author).to eq(author)
        end
      end
    end

    context 'when the attributes hash doesn''t contain an author' do
      context 'and contains a list of authors' do
        it 'should populate the pod''s author with the author list from the attributes' do
          pod.populate(authors: author_list)
          expect(pod.author).to eq(author_list.join(', '))
        end
      end

      context 'and a hash of authors' do
        it 'should populate the pod''s author with the author from the attributes' do
          pod.populate(authors: author_hash)
          expect(pod.author).to eq(author_hash.map { |name, email| "#{name} <#{email}>"}.join(', '))
        end
      end
    end

    context 'when the attributes hash contains a summary' do
      context 'and a description' do
        it 'should populate the pod''s description with the description from the attributes' do
          pod.populate(summary: summary, description: description)
          expect(pod.description).to eq(description)
        end
      end

      context 'and no description' do
        it 'should populate the pod''s description with the summary from the attributes' do
          pod.populate(summary: summary)
          expect(pod.description).to eq(summary)
        end
      end
    end

    context 'when the attributes hash contains a license' do
      context 'as hash without type' do
        let(:license) { { :file => 'MIT-LICENSE.txt' } }

        it 'should set the license to nil' do
          pod.populate(license: license)
          expect(pod.license).to be_nil
        end
      end

      context 'which exists' do
        context 'as text' do
          let(:license) { 'MIT' }

          it 'should set a license with id' do
            pod.populate(license: license)
            expect(pod.license).not_to be_nil
            expect(pod.license.identifier).to eq(license)
            expect(pod.license.identifier_type).to eq(:id)
            expect(pod.license.text).to be_nil
            expect(pod.license.url).to be_nil
          end
        end

        context 'as hash' do
          it 'should accept both symbols and strings as attribute names' do
            pod.populate(license: { :type => 'MIT' })
            expect(pod.license).not_to be_nil
            expect(pod.license.identifier).to eq('MIT')
            expect(pod.license.identifier_type).to eq(:id)

            pod.populate(license: { 'type' => 'MIT' })
            expect(pod.license).not_to be_nil
            expect(pod.license.identifier).to eq('MIT')
            expect(pod.license.identifier_type).to eq(:id)
          end

          context 'with file' do
            let(:license) { { :type => 'MIT', :file => 'MIT-LICENSE.txt' } }

            it 'should set a license with id' do
              pod.populate(license: license)
              expect(pod.license).not_to be_nil
              expect(pod.license.identifier).to eq(license[:type])
              expect(pod.license.identifier_type).to eq(:id)
              expect(pod.license.text).to be_nil
              expect(pod.license.url).to be_nil
            end
          end

          context 'with text' do
            let(:license) {
              { :type => 'MIT',
                :text => <<-LICENSE
                Copyright 2012
                Permission is granted to...
                LICENSE
              }
            }

            it 'should set a license with id' do
              pod.populate(license: license)
              expect(pod.license).not_to be_nil
              expect(pod.license.identifier).to eq(license[:type])
              expect(pod.license.identifier_type).to eq(:id)
              expect(pod.license.text).to eq(license[:text])
              expect(pod.license.url).to be_nil
            end
          end
        end
      end

      context 'which doesn''t exist' do
        context 'as text' do
          let(:license) { 'Custom license' }

          it 'should set a license with name' do
            pod.populate(license: license)
            expect(pod.license).not_to be_nil
            expect(pod.license.identifier).to eq(license)
            expect(pod.license.identifier_type).to eq(:name)
            expect(pod.license.text).to be_nil
            expect(pod.license.url).to be_nil
          end
        end

        context 'as hash' do
          it 'should accept both symbols and strings as attribute names' do
            pod.populate(license: { :type => 'Custom license' })
            expect(pod.license).not_to be_nil
            expect(pod.license.identifier).to eq('Custom license')
            expect(pod.license.identifier_type).to eq(:name)

            pod.populate(license: { 'type' => 'Custom license' })
            expect(pod.license).not_to be_nil
            expect(pod.license.identifier).to eq('Custom license')
            expect(pod.license.identifier_type).to eq(:name)
          end

          context 'with file' do
            let(:license) { { :type => 'Custom license', :file => 'LICENSE.txt' } }

            it 'should set a license with name' do
              pod.populate(license: license)
              expect(pod.license).not_to be_nil
              expect(pod.license.identifier).to eq(license[:type])
              expect(pod.license.identifier_type).to eq(:name)
              expect(pod.license.text).to be_nil
              expect(pod.license.url).to be_nil
            end
          end

          context 'with text' do
            let(:license) {
              { :type => 'Custom license',
                :text => <<-LICENSE
                Copyright 2012
                Permission is granted to...
                LICENSE
              }
            }

            it 'should set a license with name' do
              pod.populate(license: license)
              expect(pod.license).not_to be_nil
              expect(pod.license.identifier).to eq(license[:type])
              expect(pod.license.identifier_type).to eq(:name)
              expect(pod.license.text).to eq(license[:text])
              expect(pod.license.url).to be_nil
            end
          end
        end
      end
    end

    context 'when the attributes hash contains a homepage' do
      it 'should populate the pod''s homepage with the homepage from the attributes' do
        pod.populate(homepage: homepage)
        expect(pod.homepage).to eq(homepage)
      end
    end
  end
end