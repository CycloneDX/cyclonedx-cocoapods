require 'rspec'
require 'cyclonedx/cocoapods/pod'

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
      let(:valid_pod_names) { ['Alamofire', '  FirebaseAnalytics', 'R.swift   ', '   Sentry   ', 'Dèja%Vú'] }

      it 'should strip the name' do
        pods = valid_pod_names.map { |pod_name| described_class.new(name: pod_name, version: '1.0.0') }
        expect(pods.map(&:name)).to eq(valid_pod_names.map(&:strip))
      end

      context 'and an invalid version' do
        it 'should raise an error' do
          expect { described_class.new(name: valid_pod_names[0], version: 'this.is-not_A_version') }.to raise_error(ArgumentError)
        end
      end

      context 'and a valid version' do
        let(:valid_versions) { ['5.0', '6.8.3', '2.2.0-alpha.372'] }
        let(:valid_pod_names_and_versions) { valid_pod_names.product(valid_versions) }

        context 'without checksum' do
          before(:each) do
            @valid_pods = valid_pod_names_and_versions.map { |name, version| described_class.new(name: name, version: version) }
          end

          it 'should properly build the pod' do
            expect(@valid_pods.map(&:name)).to eq(valid_pod_names_and_versions.map { |pair| pair[0] }.map(&:strip))
            expect(@valid_pods.map(&:version)).to eq(valid_pod_names_and_versions.map { |pair| pair[1] })
            expect(@valid_pods.map(&:checksum)).to eq(valid_pod_names_and_versions.map { nil })
          end

          it 'should return a proper purl' do
            expected_purls = valid_pod_names_and_versions.map { |name, version| "pkg:pod/#{CGI.escape(name.strip)}@#{version}" }
            expect(@valid_pods.map(&:purl)).to eq(expected_purls)
          end
        end

        context 'with a valid checksum' do
          let(:valid_checksum) { '9a8ccc3a24b87624f4b40883adab3d98a9fdc00d' }

          before(:each) do
            @valid_pods = valid_pod_names_and_versions.map { |name, version| described_class.new(name: name, version: version, checksum: valid_checksum) }
          end

          it 'should properly build the pod' do
            expect(@valid_pods.map(&:name)).to eq(valid_pod_names_and_versions.map { |pair| pair[0] }.map(&:strip))
            expect(@valid_pods.map(&:version)).to eq(valid_pod_names_and_versions.map { |pair| pair[1] })
            expect(@valid_pods.map(&:checksum)).to eq(valid_pod_names_and_versions.map { valid_checksum })
          end

          it 'should return a proper purl' do
            expected_purls = valid_pod_names_and_versions.map { |name, version| "pkg:pod/#{CGI.escape(name.strip)}@#{version}" }
            expect(@valid_pods.map(&:purl)).to eq(expected_purls)
          end
        end

        context 'with an invalid checksum' do
          it 'should raise an error' do
            expect {
              described_class.new(name: valid_pod_names.sample, version: valid_versions.sample, checksum: 'not-a-valid-checksum')
            }.to raise_error(ArgumentError)
          end
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

    context 'when the attributes hash contains a license' do
      context 'as hash without type' do
        let(:license) { { :file => 'MIT-LICENSE.txt' } }

        it 'should set the license to nil' do
          @pod.populate(license: license)
          expect(@pod.license).to be_nil
        end
      end

      context 'which exists' do
        context 'as text' do
          let(:license) { 'MIT' }

          it 'should set a license with id' do
            @pod.populate(license: license)
            expect(@pod.license).not_to be_nil
            expect(@pod.license.identifier).to eq(license)
            expect(@pod.license.identifier_type).to eq(:id)
            expect(@pod.license.text).to be_nil
            expect(@pod.license.url).to be_nil
          end
        end

        context 'as hash' do
          it 'should accept both symbols and strings as attribute names' do
            @pod.populate(license: { :type => 'MIT' })
            expect(@pod.license).not_to be_nil
            expect(@pod.license.identifier).to eq('MIT')
            expect(@pod.license.identifier_type).to eq(:id)

            @pod.populate(license: { 'type' => 'MIT' })
            expect(@pod.license).not_to be_nil
            expect(@pod.license.identifier).to eq('MIT')
            expect(@pod.license.identifier_type).to eq(:id)
          end

          context 'with file' do
            let(:license) { { :type => 'MIT', :file => 'MIT-LICENSE.txt' } }

            it 'should set a license with id' do
              @pod.populate(license: license)
              expect(@pod.license).not_to be_nil
              expect(@pod.license.identifier).to eq(license[:type])
              expect(@pod.license.identifier_type).to eq(:id)
              expect(@pod.license.text).to be_nil
              expect(@pod.license.url).to be_nil
            end
          end

          context 'with text' do
            let(:license) {
              { :type => 'MIT',
                :text => <<-LICENSE
                Copyright 2012
                Permission is granted to...
                LICENSE
              }
            }

            it 'should set a license with id' do
              @pod.populate(license: license)
              expect(@pod.license).not_to be_nil
              expect(@pod.license.identifier).to eq(license[:type])
              expect(@pod.license.identifier_type).to eq(:id)
              expect(@pod.license.text).to eq(license[:text])
              expect(@pod.license.url).to be_nil
            end
          end
        end
      end

      context 'which doesn''t exist' do
        context 'as text' do
          let(:license) { 'Custom license' }

          it 'should set a license with name' do
            @pod.populate(license: license)
            expect(@pod.license).not_to be_nil
            expect(@pod.license.identifier).to eq(license)
            expect(@pod.license.identifier_type).to eq(:name)
            expect(@pod.license.text).to be_nil
            expect(@pod.license.url).to be_nil
          end
        end

        context 'as hash' do
          it 'should accept both symbols and strings as attribute names' do
            @pod.populate(license: { :type => 'Custom license' })
            expect(@pod.license).not_to be_nil
            expect(@pod.license.identifier).to eq('Custom license')
            expect(@pod.license.identifier_type).to eq(:name)

            @pod.populate(license: { 'type' => 'Custom license' })
            expect(@pod.license).not_to be_nil
            expect(@pod.license.identifier).to eq('Custom license')
            expect(@pod.license.identifier_type).to eq(:name)
          end

          context 'with file' do
            let(:license) { { :type => 'Custom license', :file => 'LICENSE.txt' } }

            it 'should set a license with name' do
              @pod.populate(license: license)
              expect(@pod.license).not_to be_nil
              expect(@pod.license.identifier).to eq(license[:type])
              expect(@pod.license.identifier_type).to eq(:name)
              expect(@pod.license.text).to be_nil
              expect(@pod.license.url).to be_nil
            end
          end

          context 'with text' do
            let(:license) {
              { :type => 'Custom license',
                :text => <<-LICENSE
                Copyright 2012
                Permission is granted to...
                LICENSE
              }
            }

            it 'should set a license with name' do
              @pod.populate(license: license)
              expect(@pod.license).not_to be_nil
              expect(@pod.license.identifier).to eq(license[:type])
              expect(@pod.license.identifier_type).to eq(:name)
              expect(@pod.license.text).to eq(license[:text])
              expect(@pod.license.url).to be_nil
            end
          end
        end
      end
    end
  end
end