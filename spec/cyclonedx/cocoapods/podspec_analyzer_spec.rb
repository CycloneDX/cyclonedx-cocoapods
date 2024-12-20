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

require 'cyclonedx/cocoapods/podspec_analyzer'
require 'rspec'

RSpec.describe CycloneDX::CocoaPods::PodspecAnalyzer do
  let(:fixtures) { Pathname.new(File.expand_path('../../fixtures', __dir__)) }
  let(:simple_pod) { 'SimplePod/SimplePod.podspec' }

  Pod::Config.instance.installation_root = "#{File.expand_path('../../fixtures', __dir__)}/"

  before(:each) do
    @log = StringIO.new
    @logger = Logger.new(@log)
  end

  context 'Calling ensure_podspec_is_present' do
    it 'with bad path should raise an error' do
      analyzer = CycloneDX::CocoaPods::PodspecAnalyzer.new(logger: @logger)

      options = {
        path: 'bad_path_that_does_not_exist'
      }
      expect do
        analyzer.ensure_podspec_is_present(options)
      end.to raise_error(CycloneDX::CocoaPods::PodspecParsingError,
                         'bad_path_that_does_not_exist is not a valid directory.')
    end

    it 'with EmptyPodfile fixture should return nil when no podspec exists' do
      analyzer = CycloneDX::CocoaPods::PodspecAnalyzer.new(logger: @logger)

      options = {
        path: fixtures + 'EmptyPodfile/'
      }
      podspecs = analyzer.ensure_podspec_is_present(options)
      expect(podspecs).to be_nil
    end
  end

  context 'parsing podspec' do
    it 'should parse SimplePod podspec correctly' do
      analyzer = CycloneDX::CocoaPods::PodspecAnalyzer.new(logger: @logger)

      options = {
        path: fixtures + 'SimplePod/',
        podspec_path: fixtures + simple_pod
      }
      podspecs = analyzer.ensure_podspec_is_present(options)
      pod = analyzer.parse_podspec(podspecs)

      expect(pod.name).to eq('SampleProject')
      expect(pod.version).to eq('1.0.0')
      expect(pod.source).not_to be_nil
      expect(pod.source.url).to include('github.com')
    end
  end

  context 'parsing git source information' do
    it 'should handle git repository with tag' do
      analyzer = CycloneDX::CocoaPods::PodspecAnalyzer.new(logger: @logger)

      options = {
        path: fixtures + 'SimplePod/',
        podspec_path: fixtures + simple_pod
      }
      podspecs = analyzer.ensure_podspec_is_present(options)
      pod = analyzer.parse_podspec(podspecs)

      expect(pod.source.type).to eq(:tag)
      expect(pod.source.label).not_to be_nil
    end
  end
end
