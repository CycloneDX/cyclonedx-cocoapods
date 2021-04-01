require 'rspec'
require 'cyclonedx/pod'

RSpec.describe CycloneDX::CocoaPods::Pod do
  context 'when creating new pods' do
    context 'with a nil name' do
      it 'should raise an error' do
        expect { described_class.new(name: nil, version: '1.3.5') }.to raise_error(ArgumentError)
      end
    end

    context 'with an empty name' do
      it 'should raise an error' do
        expect { described_class.new(name: '  ', version: '1.3.5') }.to raise_error(ArgumentError)
      end
    end

    context 'with a valid name' do
      before(:all) do
        @valid_pod_names = ['Alamofire', '  FirebaseAnalytics', 'R.swift   ', '   Sentry   ']
      end

      it 'should strip the name' do
        pods = @valid_pod_names.map { |pod_name| described_class.new(name: pod_name, version: '1.0.0') }
        expect(pods.map(&:name)).to eq(@valid_pod_names.map(&:strip))
      end

      context 'and an invalid version' do
        it 'should raise an error' do
          expect { described_class.new(name: @valid_pod_names[0], version: 'this.is-not_A_version') }.to raise_error(ArgumentError)
        end
      end

      context 'and a valid version' do
        before(:all) do
          @valid_versions = ['5.0', '6.8.3', '2.2.0-alpha.372']
          @valid_pod_names_and_versions = @valid_pod_names.product(@valid_versions)
        end

        before(:each) do
          @valid_pods = @valid_pod_names_and_versions.map { |name, version| described_class.new(name: name, version: version) }
        end

        it 'should properly build the pod' do
          expect(@valid_pods.map(&:name)).to eq(@valid_pod_names_and_versions.map { |pair| pair[0] }.map(&:strip))
          expect(@valid_pods.map(&:version)).to eq(@valid_pod_names_and_versions.map { |pair| pair[1] }.map { |version| Gem::Version.new(version) })
        end

        it 'should return a proper purl' do
          expected_purls = @valid_pod_names_and_versions.map { |name, version| "pkg:pod/#{name.strip}@#{Gem::Version.new(version).to_s}" }
          expect(@valid_pods.map(&:purl)).to eq(expected_purls)
        end
      end
    end
  end
end