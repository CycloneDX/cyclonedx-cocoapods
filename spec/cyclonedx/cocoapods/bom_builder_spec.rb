require 'rspec'
require 'rspec/matchers'
require 'equivalent-xml'
require 'cyclonedx/cocoapods/version'
require 'cyclonedx/cocoapods/bom_builder'

RSpec.describe CycloneDX::CocoaPods::Pod do
  let(:pod_name) { 'Alamofire' }
  let(:pod_version) { '5.4.2' }
  let(:checksum) { '9a8ccc3a24b87624f4b40883adab3d98a9fdc00d' }
  let(:author) { 'Darth Vader' }
  let(:summary) { 'Elegant HTTP Networking in Swift' }
  let(:homepage) { 'https://github.com/Alamofire/Alamofire' }

  before(:each) do
    @pod = described_class.new(name: pod_name, version: pod_version, checksum: checksum)
  end

  context 'when generating a pod component in a BOM' do
    before(:each) do
      @xml = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        @pod.add_to_bom(xml)
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
        expect(@xml.at('/component/publisher')).to be_nil
      end
    end

    context 'when having an author' do
      before(:each) do
        @pod.populate(author: author)
        @xml = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          @pod.add_to_bom(xml)
        end.to_xml)
      end

      it 'should generate a correct component author' do
        expect(@xml.at('/component/author')).not_to be_nil
        expect(@xml.at('/component/author').text).to eql(@pod.author)
        expect(@xml.at('/component/publisher')).not_to be_nil
        expect(@xml.at('/component/publisher').text).to eql(@pod.author)
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
          @pod.add_to_bom(xml)
        end.to_xml)
      end

      it 'should generate a correct component description' do
        expect(@xml.at('/component/description')).not_to be_nil
        expect(@xml.at('/component/description').text).to eql(@pod.description)
      end
    end

    context 'when not having a checksum' do
      before(:each) do
        @pod = described_class.new(name: pod_name, version: pod_version)
        @xml = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          @pod.add_to_bom(xml)
        end.to_xml)
      end

      it 'shouldn''t generate a component hash' do
        expect(@xml.at('/component/hashes')).to be_nil
      end
    end

    context 'when having a checksum' do
      it 'should generate a correct component hash' do
        expect(@xml.at('/component/hashes/hash')).not_to be_nil
        expect(@xml.at('/component/hashes/hash')['alg']).to eq(described_class::CHECKSUM_ALGORITHM)  # CocoaPods always uses SHA-1
        expect(@xml.at('/component/hashes/hash').text).to eql(@pod.checksum)
      end
    end

    context 'when not having a license' do
      it 'shouldn''t generate a license list' do
        expect(@xml.at('/component/licenses')).to be_nil
      end
    end

    context 'when having a license' do
      before(:each) do
        @pod.populate(license: 'MIT')
        @xml = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          @pod.add_to_bom(xml)
        end.to_xml)
      end

      it 'should generate a child licenses node' do
        expect(@xml.at('/component/licenses')).not_to be_nil
      end

      it 'should properly delegate license node generation' do
        license_generated_from_pod = @xml.xpath('/component/licenses/license')[0]

        license = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          @pod.license.add_to_bom(xml)
        end.to_xml).at('/license')

        expect(license_generated_from_pod).to be_equivalent_to(license)
      end
    end

    context 'when not having a homepage' do
      it 'shouldn''t generate an external references list' do
        expect(@xml.at('/component/externalReferences')).to be_nil
      end
    end

    context 'when having a homepage' do
      before(:each) do
        @pod.populate(homepage: homepage)
        @xml = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          @pod.add_to_bom(xml)
        end.to_xml)
      end

      it 'should properly generate a component external references list' do
        expect(@xml.at('/component/externalReferences')).not_to be_nil
        expect(@xml.at('/component/externalReferences/reference')).not_to be_nil
        expect(@xml.at('/component/externalReferences/reference')['type']).to eq(described_class::HOMEPAGE_REFERENCE_TYPE)
        expect(@xml.at('/component/externalReferences/reference/url')).not_to be_nil
        expect(@xml.at('/component/externalReferences/reference/url').text).to eq(homepage)
      end
    end
  end
end


RSpec.describe CycloneDX::CocoaPods::Pod::License do
  context 'when generating a license in a BOM' do
    context 'for known licenses' do
      before(:each) do
        @license = described_class.new(identifier: described_class::SPDX_LICENSES.sample)
        @xml = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          @license.add_to_bom(xml)
        end.to_xml)
      end

      it 'should generate a root license element' do
        expect(@xml.at('/license')).not_to be_nil
      end

      it 'should generate a correct license identifier' do
        expect(@xml.at('/license/id')).not_to be_nil
        expect(@xml.at('/license/id').text).to eq(@license.identifier)
        expect(@xml.at('/license/name')).to be_nil
      end

      it 'should not create text or url elements' do
        expect(@xml.at('/license/text')).to be_nil
        expect(@xml.at('/license/url')).to be_nil
      end

      context 'which includes text' do
        before(:each) do
          @license.text = "Copyright 2012\nPermission is granted to..."
          @xml = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            @license.add_to_bom(xml)
          end.to_xml)
        end

        it 'should create text element' do
          expect(@xml.at('/license/text')).not_to be_nil
          expect(@xml.at('/license/text').text).to eq(@license.text)
        end
      end

      context 'which includes url' do
        before(:each) do
          @license.url = "https://opensource.org/licenses/MIT"
          @xml = Nokogiri::XML(Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            @license.add_to_bom(xml)
          end.to_xml)
        end

        it 'should create text element' do
          expect(@xml.at('/license/url')).not_to be_nil
          expect(@xml.at('/license/url').text).to eq(@license.url)
        end
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
        @pods.each { |pod| expect(pod).to receive(:add_to_bom) }
        expect(Nokogiri::XML(@bom_builder.bom).root['version']).to eq('1')
      end

      context 'twice' do
        it 'should generate different serial numbers' do
          @pods.each { |pod| expect(pod).to receive(:add_to_bom).twice }
          original_serial_number = Nokogiri::XML(@bom_builder.bom).root['serialNumber']
          expect(Nokogiri::XML(@bom_builder.bom).root['serialNumber']).not_to eq(original_serial_number)
        end
      end
    end

    context 'with a valid version' do
      let(:version) { 53 }

      before(:each) do
        @pods.each { |pod| expect(pod).to receive(:add_to_bom) }
        @xml = Nokogiri::XML(@bom_builder.bom(version: version))
      end

      it 'should use the provided version' do
        expect(@xml.root['version']).to eq(version.to_s)
      end

      it 'should be able to use integer-ish versions' do
        @pods.each { |pod| expect(pod).to receive(:add_to_bom) }
        version = '53'
        expect(Nokogiri::XML(@bom_builder.bom(version: version)).root['version']).to eq(version)
      end

      it 'should generate a proper root node' do
        root = @xml.root

        expect(root.name).to eq('bom')
        expect(root.namespace.href).to eq(described_class::NAMESPACE)
        expect(root['version']).to eq(version.to_s)
        expect(root['serialNumber']).to match(/urn:uuid:.*/)
      end

      it 'should include a timestamp in the metadata' do
        expect(@xml.at('metadata/timestamp')).not_to be_nil
      end

      it 'should generate tools metadata' do
        expect(@xml.at('metadata/tools')).not_to be_nil

        # First tool should be cyclonedx-cocoapods
        expect(@xml.css('metadata/tools/tool[1]/name').text).to eq('cyclonedx-cocoapods')
        expect(@xml.css('metadata/tools/tool[1]/version').text).to eq(CycloneDX::CocoaPods::VERSION)

        # Check rest of tools
        expect(@xml.css('metadata/tools/tool/name').drop(1).map(&:text).map(&:to_sym).to_set).to eq(CycloneDX::CocoaPods::DEPENDENCIES.keys.to_set)
        @xml.css('metadata/tools/tool').drop(1).each do |tool|
          tool_name = tool.at('name').text
          tool_version = tool.at('version').text
          expect(CycloneDX::CocoaPods::DEPENDENCIES[tool_name.to_sym]).to eq(tool_version)
        end
      end

      it 'should generate a child components node' do
        expect(@xml.at('bom/components')).not_to be_nil
      end

      it 'should generate a component for each pod' do
        # Tested in expect included in before(:each)
      end

      context 'twice' do
        it 'should generate different serial numbers' do
          @pods.each { |pod| expect(pod).to receive(:add_to_bom).twice }
          original_serial_number = Nokogiri::XML(@bom_builder.bom(version: 53)).root['serialNumber']
          expect(Nokogiri::XML(@bom_builder.bom(version: 53)).root['serialNumber']).not_to eq(original_serial_number)
        end
      end
    end
  end
end