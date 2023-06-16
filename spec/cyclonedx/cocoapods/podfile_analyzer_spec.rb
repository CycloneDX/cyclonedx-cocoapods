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

require 'cyclonedx/cocoapods/podfile_analyzer'
require 'rspec'

RSpec.describe CycloneDX::CocoaPods::PodfileAnalyzer do
  let(:fixtures) { Pathname.new(File.expand_path('../../../fixtures/', __FILE__)) }
  let(:empty_podfile) { 'EmptyPodfile/Podfile' }
  let(:simple_pod) { 'SimplePod/Podfile' }
  let(:restricted_pod) { 'RestrictedPod/Podfile' }
  let(:tests_pod) { 'TestingPod/Podfile' }

  ::Pod::Config.instance.installation_root = File.expand_path('../../../fixtures/', __FILE__) + '/'

  before(:each) do
    @log = StringIO.new
    @logger = Logger.new(@log)
  end

  context 'parsing pods' do
    context 'when created with standard parameters' do
      it 'should handle no pods correctly' do
        analyzer = ::CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

        pod_file = ::Pod::Podfile.from_file(fixtures + empty_podfile)
        expect(pod_file).not_to be_nil
        lock_file = ::Pod::Lockfile.from_file(fixtures + (empty_podfile + '.lock'))
        expect(lock_file).not_to be_nil

        included_pods = analyzer.parse_pods(pod_file, lock_file)

        pod_names = included_pods.map(&:name)
        expect(pod_names).to eq([])
      end

      it 'should find all simple pods' do
        analyzer = ::CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

        pod_file = ::Pod::Podfile.from_file(fixtures + simple_pod)
        expect(pod_file).not_to be_nil
        lock_file = ::Pod::Lockfile.from_file(fixtures + (simple_pod + '.lock'))
        expect(lock_file).not_to be_nil

        included_pods = analyzer.parse_pods(pod_file, lock_file)

        pod_names = included_pods.map(&:name)
        expect(pod_names).to eq(['Alamofire', 'MSAL', 'MSAL/app-lib'])
      end

      it 'should find all pods actually used' do
        analyzer = ::CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

        pod_file = ::Pod::Podfile.from_file(fixtures + restricted_pod)
        expect(pod_file).not_to be_nil
        lock_file = ::Pod::Lockfile.from_file(fixtures + (restricted_pod + '.lock'))
        expect(lock_file).not_to be_nil

        included_pods = analyzer.parse_pods(pod_file, lock_file)

        pod_names = included_pods.map(&:name)
        expect(pod_names).to eq(['EFQRCode'])
      end

      it 'should find all pods' do
        analyzer = ::CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

        pod_file = ::Pod::Podfile.from_file(fixtures + tests_pod)
        expect(pod_file).not_to be_nil
        lock_file = ::Pod::Lockfile.from_file(fixtures + (tests_pod + '.lock'))
        expect(lock_file).not_to be_nil

        included_pods = analyzer.parse_pods(pod_file, lock_file)

        pod_names = included_pods.map(&:name)
        expect(pod_names).to eq(['Alamofire', 'MSAL', 'MSAL/app-lib'])
      end
    end

    context 'when configured to exclude test pods' do
      it 'should find all simple pods' do
        analyzer = ::CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger, exclude_test_targets: true)

        pod_file = ::Pod::Podfile.from_file(fixtures + simple_pod)
        expect(pod_file).not_to be_nil
        lock_file = ::Pod::Lockfile.from_file(fixtures + (simple_pod + '.lock'))
        expect(lock_file).not_to be_nil

        included_pods = analyzer.parse_pods(pod_file, lock_file)

        pod_names = included_pods.map(&:name)
        expect(pod_names).to eq(['Alamofire', 'MSAL', 'MSAL/app-lib'])
      end

      it 'should not include testing pods' do
        analyzer = ::CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger, exclude_test_targets: true)

        pod_file = ::Pod::Podfile.from_file(fixtures + tests_pod)
        expect(pod_file).not_to be_nil
        lock_file = ::Pod::Lockfile.from_file(fixtures + (tests_pod + '.lock'))
        expect(lock_file).not_to be_nil

        included_pods = analyzer.parse_pods(pod_file, lock_file)

        pod_names = included_pods.map(&:name)
        expect(pod_names).to eq(['Alamofire'])
      end
    end
  end
end
