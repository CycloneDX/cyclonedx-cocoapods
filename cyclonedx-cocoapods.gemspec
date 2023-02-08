# frozen_string_literal: true

require_relative 'lib/cyclonedx/cocoapods/version'

Gem::Specification.new do |spec|
  spec.name          = 'cyclonedx-cocoapods'
  spec.version       = CycloneDX::CocoaPods::VERSION
  spec.authors       = ['José González', 'Kyle Hammond']
  spec.email         = ['jose.gonzalez@openinput.com', 'kyle.hammond@jamf.com']

  spec.summary       = 'CycloneDX software bill-of-material (SBOM) generation utility'
  spec.description   = 'CycloneDX is a lightweight software bill-of-material (SBOM) specification designed for use in application security contexts and supply chain component analysis. This Gem generates CycloneDX BOMs from CocoaPods projects.'
  spec.homepage      = 'https://github.com/CycloneDX/cyclonedx-cocoapods'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/CycloneDX/cyclonedx-cocoapods.git'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir['lib/**/*.{rb,json}'] + %w{ exe/cyclonedx-cocoapods README.md CHANGELOG.md LICENSE NOTICE }

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'cocoapods', ['>= 1.10.1', '< 2.0']
  spec.add_runtime_dependency 'nokogiri', ['>= 1.11.2', '< 2.0']

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'equivalent-xml', '~> 0.6.0'
end
