# frozen_string_literal: true

require_relative "lib/cyclonedx/cocoapods/version"

Gem::Specification.new do |spec|
  spec.name          = "cyclonedx-cocoapods"
  spec.version       = CycloneDX::CocoaPods::VERSION
  spec.authors       = ["José González"]
  spec.email         = ["jose.gonzalez@openinput.com"]

  spec.summary       = "CycloneDX software bill-of-material (SBoM) generation utility"
  spec.description   = "CycloneDX is a lightweight software bill-of-material (SBOM) specification designed for use in application security contexts and supply chain component analysis. This Gem generates CycloneDX BOMs from CocoaPods projects."
  spec.homepage      = "https://github.com/CycloneDX/cyclonedx-cocoapods"
  spec.license       = "Apache-2.0"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/CycloneDX/cyclonedx-cocoapods.git"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
