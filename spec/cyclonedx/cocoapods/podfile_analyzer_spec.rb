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
  let(:fixtures) { Pathname.new(File.expand_path('../../fixtures', __dir__)) }
  let(:empty_podfile) { 'EmptyPodfile/Podfile' }
  let(:large_podfile) { 'LargePodfile/Podfile' }
  let(:simple_pod) { 'SimplePod/Podfile' }
  let(:restricted_pod) { 'RestrictedPod/Podfile' }
  let(:tests_pod) { 'TestingPod/Podfile' }

  Pod::Config.instance.installation_root = "#{File.expand_path('../../fixtures', __dir__)}/"

  before(:each) do
    @log = StringIO.new
    @logger = Logger.new(@log)
  end

  context 'Calling ensure_podfile_and_lock_are_present' do
    it 'with bad path should raise an error' do
      analyzer = CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

      options = {
        path: 'bad_path_that_does_not_exist'
      }
      expect do
        analyzer.ensure_podfile_and_lock_are_present(options)
      end.to raise_error(CycloneDX::CocoaPods::PodfileParsingError,
                         'bad_path_that_does_not_exist is not a valid directory.')
    end

    it 'with SimplePod fixture should succeed' do
      analyzer = CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

      options = {
        path: fixtures + 'SimplePod/'
      }
      podfile, lockfile = analyzer.ensure_podfile_and_lock_are_present(options)
      expect(podfile).not_to be_nil
      expect(lockfile).not_to be_nil
    end

    it 'with EmptyPodfile fixture should raise a "Missing Manifest.lock" error' do
      analyzer = CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

      options = {
        path: fixtures + 'EmptyPodfile/'
      }
      expect do
        analyzer.ensure_podfile_and_lock_are_present(options)
      end.to raise_error(CycloneDX::CocoaPods::PodfileParsingError,
                         "Missing Manifest.lock, please run 'pod install' before generating BOM")
    end

    it 'with PluginPod fixture should log a warning when trying to load the plugin' do
      analyzer = CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

      options = {
        path: fixtures + 'PluginPod/'
      }
      expect(@logger).to receive(:warn).with(/Failed to load plugin fake_plugin_that_does_not_exist./)
      podfile, lockfile = analyzer.ensure_podfile_and_lock_are_present(options)
      expect(podfile).not_to be_nil
      expect(lockfile).not_to be_nil
    end
  end

  context 'parsing pods' do
    context 'when created with standard parameters' do
      it 'should handle no pods correctly' do
        analyzer = CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

        pod_file = Pod::Podfile.from_file(fixtures + empty_podfile)
        expect(pod_file).not_to be_nil
        lock_file = Pod::Lockfile.from_file(fixtures + "#{empty_podfile}.lock")
        expect(lock_file).not_to be_nil

        included_pods, dependencies = analyzer.parse_pods(pod_file, lock_file)

        pod_names = included_pods.map(&:name)
        expect(pod_names).to eq([])
        expect(dependencies).to eq({})
        expect(pod_names.length).to eq(dependencies.length)
      end

      it 'should load large podfiles quickly' do
        analyzer = CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

        pod_file = Pod::Podfile.from_file(fixtures + large_podfile)
        expect(pod_file).not_to be_nil
        lock_file = Pod::Lockfile.from_file(fixtures + "#{large_podfile}.lock")
        expect(lock_file).not_to be_nil

        included_pods, dependencies = analyzer.parse_pods(pod_file, lock_file)

        # Only 104 pods listed in the Podfile, but there are 187 pods counting all 104 plus dependencies.
        expect(included_pods.count).to eq(187)
        # There are 187 pods here!  We only verify some of them.
        pod_names = included_pods.map(&:name)
        expect(pod_names.first(6)).to eq(['boost', 'DoubleConversion', 'Dynatrace',
                                          'Dynatrace/xcframework', 'EXApplication', 'EXConstants'])
        expect(pod_names.last(5)).to eq(['VisionCameraOcr', 'Yoga', 'ZXingObjC/Core',
                                         'ZXingObjC/OneD', 'ZXingObjC/PDF417'])
        # rubocop:disable Layout/LineLength
        expect(dependencies.first).to eq([
                                           'pkg:cocoapods/boost@1.83.0?download_url=..%2Fnode_modules%2Freact-native%2Fthird-party-podspecs%2Fboost.podspec',
                                           []
                                         ])
        # rubocop:enable Layout/LineLength

        # Each of the pods should have an entry in the dependencies hash
        expect(pod_names.length).to eq(dependencies.length)
      end

      it 'should find all simple pods' do
        analyzer = CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

        pod_file = Pod::Podfile.from_file(fixtures + simple_pod)
        expect(pod_file).not_to be_nil
        lock_file = Pod::Lockfile.from_file(fixtures + "#{simple_pod}.lock")
        expect(lock_file).not_to be_nil

        included_pods, dependencies = analyzer.parse_pods(pod_file, lock_file)

        pod_names = included_pods.map(&:name)
        expect(pod_names).to eq(['Alamofire', 'MSAL', 'MSAL/app-lib'])
        expect(dependencies).to eq({
                                     'pkg:cocoapods/Alamofire@5.6.2' => [],
                                     'pkg:cocoapods/MSAL@1.2.1' => ['pkg:cocoapods/MSAL@1.2.1#app-lib'],
                                     'pkg:cocoapods/MSAL@1.2.1#app-lib' => []
                                   })
        expect(pod_names.length).to eq(dependencies.length)
      end

      it 'should find all pods actually used' do
        analyzer = CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

        pod_file = Pod::Podfile.from_file(fixtures + restricted_pod)
        expect(pod_file).not_to be_nil
        lock_file = Pod::Lockfile.from_file(fixtures + "#{restricted_pod}.lock")
        expect(lock_file).not_to be_nil

        included_pods, dependencies = analyzer.parse_pods(pod_file, lock_file)

        pod_names = included_pods.map(&:name)
        expect(pod_names).to eq(['EFQRCode'])
        expect(dependencies).to eq({ 'pkg:cocoapods/EFQRCode@6.2.1' => [] })
        expect(pod_names.length).to eq(dependencies.length)
      end

      it 'should find all pods' do
        analyzer = CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger)

        pod_file = Pod::Podfile.from_file(fixtures + tests_pod)
        expect(pod_file).not_to be_nil
        lock_file = Pod::Lockfile.from_file(fixtures + "#{tests_pod}.lock")
        expect(lock_file).not_to be_nil

        included_pods, dependencies = analyzer.parse_pods(pod_file, lock_file)

        pod_names = included_pods.map(&:name)
        expect(pod_names).to eq(['Alamofire', 'MSAL', 'MSAL/app-lib'])
        expect(dependencies).to eq({
                                     'pkg:cocoapods/Alamofire@5.6.2' => [],
                                     'pkg:cocoapods/MSAL@1.2.1' => ['pkg:cocoapods/MSAL@1.2.1#app-lib'],
                                     'pkg:cocoapods/MSAL@1.2.1#app-lib' => []
                                   })
        expect(pod_names.length).to eq(dependencies.length)
      end
    end

    context 'when configured to exclude test pods' do
      it 'should find all simple pods' do
        analyzer = CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger, exclude_test_targets: true)

        pod_file = Pod::Podfile.from_file(fixtures + simple_pod)
        expect(pod_file).not_to be_nil
        lock_file = Pod::Lockfile.from_file(fixtures + "#{simple_pod}.lock")
        expect(lock_file).not_to be_nil

        included_pods, dependencies = analyzer.parse_pods(pod_file, lock_file)

        pod_names = included_pods.map(&:name)
        expect(pod_names).to eq(['Alamofire', 'MSAL', 'MSAL/app-lib'])
        expect(dependencies).to eq({
                                     'pkg:cocoapods/Alamofire@5.6.2' => [],
                                     'pkg:cocoapods/MSAL@1.2.1' => ['pkg:cocoapods/MSAL@1.2.1#app-lib'],
                                     'pkg:cocoapods/MSAL@1.2.1#app-lib' => []
                                   })
        expect(pod_names.length).to eq(dependencies.length)
      end

      it 'should not include testing pods' do
        analyzer = CycloneDX::CocoaPods::PodfileAnalyzer.new(logger: @logger, exclude_test_targets: true)

        pod_file = Pod::Podfile.from_file(fixtures + tests_pod)
        expect(pod_file).not_to be_nil
        lock_file = Pod::Lockfile.from_file(fixtures + "#{tests_pod}.lock")
        expect(lock_file).not_to be_nil

        included_pods, dependencies = analyzer.parse_pods(pod_file, lock_file)

        pod_names = included_pods.map(&:name)
        expect(pod_names).to eq(['Alamofire'])
        expect(dependencies).to eq({ 'pkg:cocoapods/Alamofire@5.6.2' => [] })
        expect(pod_names.length).to eq(dependencies.length)
      end
    end
  end
end
