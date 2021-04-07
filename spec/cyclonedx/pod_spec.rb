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

  context 'when populating a pod with attributes' do
    let(:author) { 'Darth Vader' }
    let(:author_list) { ['Darth Vader', 'Wookiee'] }
    let(:author_hash) { {
      'Darth Vader' => 'darthvader@darkside.com',
      'Wookiee' => 'wookiee@aggrrttaaggrrt.com'
    } }

    let(:summary) { 'Elegant HTTP Networking in Swift' }
    let(:description) { 'Alamofire provides an elegant and composable interface to HTTP network requests.' }

    before(:each) do
      @pod = described_class.new(name: 'Alamofire', version: '5.4.2')
    end

    it 'should leave pod name and version untouched' do
      original_name = @pod.name
      original_version = @pod.version

      @pod.populate(author: author, summary: summary)

      expect(@pod.name).to eq(original_name)
      expect(@pod.version).to eq(original_version)
    end

    it 'should modify previous values of attributes' do
      @pod.populate(author: author, summary: summary)
      expect(@pod.author).to eq(author)
      expect(@pod.description).to eq(summary)

      @pod.populate(description: description)
      expect(@pod.author).to be_nil
      expect(@pod.description).to eq(description)
    end

    it 'should accept both symbols and strings as attribute names' do
      @pod.populate(author: 'Author as named parameter')
      expect(@pod.author).to eq('Author as named parameter')

      @pod.populate({ 'author' => 'Author as hash value with String key' })
      expect(@pod.author).to eq('Author as hash value with String key')

      @pod.populate({ author: 'Author as hash value with Symbol key' })
      expect(@pod.author).to eq('Author as hash value with Symbol key')
    end

    context 'when the attributes hash contains an author' do
      context 'and a list of authors' do
        it 'should populate the pod''s author with the author from the attributes' do
          @pod.populate(author: author, authors: author_list)
          expect(@pod.author).to eq(author)
        end
      end

      context 'and a hash of authors' do
        it 'should populate the pod''s author with the author from the attributes' do
          @pod.populate(author: author, authors: author_hash)
          expect(@pod.author).to eq(author)
        end
      end
    end

    context 'when the attributes hash doesn''t contain an author' do
      context 'and contains a list of authors' do
        it 'should populate the pod''s author with the author list from the attributes' do
          @pod.populate(authors: author_list)
          expect(@pod.author).to eq(author_list.join(', '))
        end
      end

      context 'and a hash of authors' do
        it 'should populate the pod''s author with the author from the attributes' do
          @pod.populate(authors: author_hash)
          expect(@pod.author).to eq(author_hash.map { |name, email| "#{name} <#{email}>"}.join(', '))
        end
      end
    end

    context 'when the attributes hash contains a summary' do
      context 'and a description' do
        it 'should populate the pod''s description with the description from the attributes' do
          @pod.populate(summary: summary, description: description)
          expect(@pod.description).to eq(description)
        end
      end

      context 'and no description' do
        it 'should populate the pod''s description with the summary from the attributes' do
          @pod.populate(summary: summary)
          expect(@pod.description).to eq(summary)
        end
      end
    end
  end
end