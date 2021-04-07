require 'rspec'
require 'cyclonedx/search_engine'

# This is far from a black box type of unit testing, but it serves the purpose of documenting
# our use of the CocoaPods classes and the expected return values, which may change between versions
# of CocoaPods.
RSpec.describe CycloneDX::CocoaPods::SearchEngine do
  let(:pod_name) { 'Alamofire' }
  let(:pod_version) { '5.4.2' }
  let(:paths) { ['/cocoapods/repos/repo1/pod/pod.json', '/cocoapods/repos/repo2/pod/pod.json'] }
  let(:attributes) { { name: pod_name, version: pod_version } }

  before(:each) do
    @source_manager = double()
    @specification_set = double()
    @specification = double()

    allow(@source_manager).to receive(:search_by_name).and_return([@specification_set])
    allow(@specification_set).to receive(:specification_paths_for_version).and_return(paths)
    allow(::Pod::Specification).to receive(:from_file).and_return(@specification)
    allow(@specification).to receive(:attributes_hash).and_return(attributes)

    @search_engine = described_class.new(source_manager: @source_manager)
  end

  context 'searching for a pod' do
    it 'should search for a pod with that exact name and version' do
      expect(@source_manager).to receive(:search_by_name).with("^#{pod_name}$")
      expect(@specification_set).to receive(:specification_paths_for_version).with(::Pod::Version.new(pod_version))
      @search_engine.attributes_for_pod_with(name: pod_name, version: pod_version)
    end

    context 'when the source manager doesn''t find any pod with the provided name' do
      before(:each) do
        allow(@source_manager).to receive(:search_by_name).and_return([])
      end

      it 'should raise an error' do
        expect {
          @search_engine.attributes_for_pod_with(name: pod_name, version: pod_version)
        }.to raise_error(CycloneDX::CocoaPods::SearchError, "No pod found named #{pod_name}")
      end
    end

    context 'when the source manager finds more than one pod with the provided name' do
      before(:each) do
        allow(@source_manager).to receive(:search_by_name).and_return([@specification_set, @specification_set])
      end

      it 'should raise an error' do
        expect {
          @search_engine.attributes_for_pod_with(name: pod_name, version: pod_version)
        }.to raise_error(CycloneDX::CocoaPods::SearchError, "More than one pod found named #{pod_name}")
      end
    end

    context 'when the source manager finds exactly one pod with the provided name' do
      context 'when the search manager doesn''t find an specification for the provided version' do
        before(:each) do
          allow(@specification_set).to receive(:specification_paths_for_version).and_return([])
        end

        it 'should raise an error' do
          expect {
            @search_engine.attributes_for_pod_with(name: pod_name, version: pod_version)
          }.to raise_error(CycloneDX::CocoaPods::SearchError, "Version #{pod_version} not found for pod #{pod_name}")
        end
      end

      context 'when the source manager finds at least a specification for the provided version' do
        it 'returns the attributes of the first specification' do
          expect(::Pod::Specification).to receive(:from_file).with(paths[0])
          expect(@search_engine.attributes_for_pod_with(name: pod_name, version: pod_version)).to eq(attributes)
        end
      end
    end
  end
end
