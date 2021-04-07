require 'rspec'
require 'cyclonedx/bom_builder'

RSpec.describe CycloneDX::CocoaPods::Pod do
  let(:pod_name) { 'Alamofire' }
  let(:pod_version) { '5.4.2' }
  let(:author) { 'Darth Vader' }
  let(:summary) { 'Elegant HTTP Networking in Swift' }

  before(:each) do
    @pod = described_class.new(name: pod_name, version: pod_version)
  end

  context 'when generating a pod component in a BOM' do
    before(:each) do
      @xml = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        @pod.add_component_to_bom(xml)
      end.to_xml)
    end

    it 'should generate a root component of type library' do
      expect(@xml.at('/component')).not_to be_nil
      expect(@xml.at('/component')['type']).to eql('library')
    end

    it 'should generate a correct component name' do
      expect(@xml.at('/component/name')).not_to be_nil
      expect(@xml.at('/component/name').text).to eql(@pod.name)
    end

    it 'should generate a correct component version' do
      expect(@xml.at('/component/version')).not_to be_nil
      expect(@xml.at('/component/version').text).to eql(@pod.version.to_s)
    end

    it 'should generate a correct component purl' do
      expect(@xml.at('/component/purl')).not_to be_nil
      expect(@xml.at('/component/purl').text).to eql(@pod.purl)
    end

    context 'when not having an author' do
      it 'shouldn''t generate a component author' do
        expect(@xml.at('/component/author')).to be_nil
      end
    end

    context 'when having an author' do
      before(:each) do
        @pod.populate(author: author)
        @xml = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          @pod.add_component_to_bom(xml)
        end.to_xml)
      end

      it 'should generate a correct component author' do
        expect(@xml.at('/component/author')).not_to be_nil
        expect(@xml.at('/component/author').text).to eql(@pod.author)
      end
    end

    context 'when not having a description' do
      it 'shouldn''t generate a component description' do
        expect(@xml.at('/component/description')).to be_nil
      end
    end

    context 'when having a description' do
      before(:each) do
        @pod.populate(summary: summary)
        @xml = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          @pod.add_component_to_bom(xml)
        end.to_xml)
      end

      it 'should generate a correct component description' do
        expect(@xml.at('/component/description')).not_to be_nil
        expect(@xml.at('/component/description').text).to eql(@pod.description)
      end
    end
  end
end


RSpec.describe CycloneDX::CocoaPods::BOMBuilder do
  before(:each) do
    @pods = Array.new(5) { double() }
    @bom_builder = described_class.new(pods: @pods)
  end

  context 'when generating a BOM' do
    context 'with an incorrect version' do
      it 'should raise for non integer versions' do
        expect { @bom_builder.bom(version: 'foo') }.to raise_error(ArgumentError)
      end

      it 'should raise for negative versions' do
        expect { @bom_builder.bom(version: -1) }.to raise_error(ArgumentError)
      end
    end

    context 'with a missing version' do
      it 'should use 1 as default version value' do
        @pods.each { |pod| expect(pod).to receive(:add_component_to_bom) }
        expect(Nokogiri::XML(@bom_builder.bom).root['version']).to eq('1')
      end

      context 'twice' do
        it 'should generate different serial numbers' do
          @pods.each { |pod| expect(pod).to receive(:add_component_to_bom).twice }
          original_serial_number = Nokogiri::XML(@bom_builder.bom).root['serialNumber']
          expect(Nokogiri::XML(@bom_builder.bom).root['serialNumber']).not_to eq(original_serial_number)
        end
      end
    end

    context 'with a valid version' do
      it 'should use the provided version' do
        @pods.each { |pod| expect(pod).to receive(:add_component_to_bom) }
        version = 53
        expect(Nokogiri::XML(@bom_builder.bom(version: version)).root['version']).to eq(version.to_s)
      end

      it 'should be able to use integer-ish versions' do
        @pods.each { |pod| expect(pod).to receive(:add_component_to_bom) }
        version = '53'
        expect(Nokogiri::XML(@bom_builder.bom(version: version)).root['version']).to eq(version)
      end

      it 'should generate a proper root node' do
        @pods.each { |pod| expect(pod).to receive(:add_component_to_bom) }

        root = Nokogiri::XML(@bom_builder.bom).root

        expect(root.name).to eq('bom')
        expect(root.namespace.href).to eq(described_class::NAMESPACE)
        expect(root['version']).to eq('1')
        expect(root['serialNumber']).to match(/urn:uuid:.*/)
      end

      it 'should generate a child components node' do
        @pods.each { |pod| expect(pod).to receive(:add_component_to_bom) }

        xml = Nokogiri::XML(@bom_builder.bom)

        expect(xml.at('bom/components')).not_to be_nil # It doesn't work with /bom/components... why?
      end

      it 'should generate a component for each pod' do
        @pods.each { |pod| expect(pod).to receive(:add_component_to_bom) }
        Nokogiri::XML(@bom_builder.bom)
      end

      context 'twice' do
        it 'should generate different serial numbers' do
          @pods.each { |pod| expect(pod).to receive(:add_component_to_bom).twice }
          original_serial_number = Nokogiri::XML(@bom_builder.bom(version: 53)).root['serialNumber']
          expect(Nokogiri::XML(@bom_builder.bom(version: 53)).root['serialNumber']).not_to eq(original_serial_number)
        end
      end
    end
  end
end