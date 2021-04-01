require 'rspec'
require 'cyclonedx/bom_builder'

RSpec.describe CycloneDX::CocoaPods::Pod do
  before(:all) do
    @pod = described_class.new(name: 'Sentry', version: '2.5.7')
  end

  before(:each) do
    @xml = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      @pod.add_component_to_bom(xml)
    end.to_xml)
  end

  context 'when generating a pod component in a BOM' do
    it 'should generate a root component of type library' do
      expect(@xml.at('/component')).not_to be_nil
      expect(@xml.at('/component')['type']).to eql('library')
    end

    it 'should generate a correct component name' do
      expect(@xml.at('/component/name').text).to eql(@pod.name)
    end

    it 'should generate a correct component version' do
      expect(@xml.at('/component/version').text).to eql(@pod.version.to_s)
    end
  end
end


RSpec.describe CycloneDX::CocoaPods::BOMBuilder do
  before(:each) do
    @pods = Array.new(5) { double() }
    @bom_builder = described_class.new(pods: @pods)
  end

  context 'when generating a BOM' do
    it 'should generate a proper root node' do
      @pods.each { |pod| expect(pod).to receive(:add_component_to_bom) }

      root = Nokogiri::XML(@bom_builder.bom).root

      expect(root.name).to eq('bom')
      expect(root.namespace.href).to eq(described_class::NAMESPACE)
      expect(root['version']).to eq(described_class::VERSION)
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
  end
end