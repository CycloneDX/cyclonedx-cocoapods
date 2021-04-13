require 'rspec'
require 'cyclonedx/cocoapods/license'

RSpec.describe CycloneDX::CocoaPods::Pod::License do
  context 'when creating a new license' do
    context 'with an empty identifier' do
      it 'should raise an error' do
        expect { described_class.new(identifier: '    ') }.to raise_error(ArgumentError)
      end
    end
    
    context 'with an identifier included in the SPDX license list (regardless of case)' do
      it 'should create a license of type id' do
        existing_license_id = described_class::SPDX_LICENSES.sample
        mangled_case_id = existing_license_id.chars.map { |c| rand(2) == 0 ? c.upcase : c.downcase }.join

        license = described_class.new(identifier: mangled_case_id)

        expect(license.identifier).to eq(existing_license_id)
        expect(license.identifier_type).to eq(:id)
      end
    end

    context 'with an identifier not included in the SPDX license list' do
      it 'should create a license of type name' do
        non_existing_license_id = 'custom-license-id'

        license = described_class.new(identifier: non_existing_license_id)

        expect(license.identifier).to eq(non_existing_license_id)
        expect(license.identifier_type).to eq(:name)
      end
    end
  end
end