Pod::Spec.new do |spec|
  spec.name         = "SampleProject"
  spec.version      = "1.0.0"
  spec.summary      = "Sample summary."
  spec.description  = "Sample description."

  spec.homepage     = "https://github.com/CycloneDX/cyclonedx-cocoapods"
  spec.license      = "Apache-2.0"
  spec.author       = { "CycloneDX SBOM Standard" => "email@address.com" }
  spec.source       = { :git => "https://github.com/CycloneDX/cyclonedx-cocoapods.git", :tag => "#{spec.version}" }
end
