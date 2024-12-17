# frozen_string_literal: true

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

    it 'with SimplePod fixture should succeed' do
      analyzer = CycloneDX::CocoaPods::PodspecAnalyzer.new(logger: @logger)

      options = {
        path: fixtures + 'SimplePod/',
        podspec_path: fixtures + simple_pod
      }
      podspecs = analyzer.ensure_podspec_is_present(options)
      expect(podspecs).not_to be_nil
      expect(podspecs.length).to eq(1)
    end

    it 'with EmptyPodfile fixture should return nil when no podspec exists' do
      analyzer = CycloneDX::CocoaPods::PodspecAnalyzer.new(logger: @logger)

      options = {
        path: fixtures + 'EmptyPodfile/'
      }
      podspecs = analyzer.ensure_podspec_is_present(options)
      expect(podspecs.first).to be_nil
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
      pod = analyzer.parse_podspec(podspecs.first)

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
      pod = analyzer.parse_podspec(podspecs.first)

      expect(pod.source.type).to eq(:tag)
      expect(pod.source.label).not_to be_nil
    end
  end
end
