require 'rspec'
require 'cyclonedx/cocoapods/source'

RSpec.describe CycloneDX::CocoaPods::Source::CocoaPodsRepository do
  context 'when created with the legacy repository URL' do
    let(:url) { 'https://github.com/CocoaPods/Specs.git' }

    it 'shouldn''t generate any source qualifier' do
      expect(described_class.new(url: url).source_qualifier).to eq({})
    end
  end

  context 'when created with the trunk value' do
    let(:url) { 'trunk' }

    it 'shouldn''t generate any source qualifier' do
      expect(described_class.new(url: url).source_qualifier).to eq({})
    end
  end

  context 'when created with an alternative repository URL' do
    let(:url) { 'https://dl.cloudsmith.io/public/owner/repository/cocoapods/index.git' }

    it 'should generate a proper source qualifier' do
      expect(described_class.new(url: url).source_qualifier).to eq({ repository_url: url })
    end
  end
end


RSpec.describe CycloneDX::CocoaPods::Source::GitRepository do
  let(:url) { 'https://github.com/gowalla/AFNetworking.git' }

  context 'when created with only a git URL' do
    it 'should generate a proper source qualifier' do
      expect(described_class.new(url: url).source_qualifier).to eq({ vcs_url: url })
    end
  end

  context 'when created with a tag' do
    let(:tag) { '0.7.0' }

    it 'should generate a proper source qualifier' do
      expect(described_class.new(url: url, label: tag, type: :tag).source_qualifier).to eq({ vcs_url: "#{url}@#{tag}" })
    end
  end

  context 'when created with a branch' do
    let(:branch) { 'dev' }

    it 'should generate a proper source qualifier' do
      expect(described_class.new(url: url, label: branch, type: :branch).source_qualifier).to eq({ vcs_url: "#{url}@#{branch}" })
    end
  end

  context 'when created with a commit' do
    let(:commit) { '082f8319af' }

    it 'should generate a proper source qualifier' do
      expect(described_class.new(url: url, label: commit, type: :commit).source_qualifier).to eq({ vcs_url: "#{url}@#{commit}" })
    end
  end
end


RSpec.describe CycloneDX::CocoaPods::Source::LocalPod do
  context 'when created with a local path' do
    let(:path) { '~/Documents/AFNetworking' }

    it 'should generate a proper source qualifier' do
      # TODO: Should we generate a source qualifier for :path dependencies?
      expect(described_class.new(path: path).source_qualifier).to eq({})
    end
  end
end


RSpec.describe CycloneDX::CocoaPods::Source::Podspec do
  context 'when created with a public URL' do
    let(:url) { 'https://example.com/JSONKit.podspec' }

    it 'should generate a proper source qualifier' do
      expect(described_class.new(url: url).source_qualifier).to eq({ download_url: url })
    end
  end
end
