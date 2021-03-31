require 'rspec'
require 'cyclonedx/cocoapods'

RSpec.describe CycloneDX::CocoaPods do
  it "has a version number" do
    expect(CycloneDX::CocoaPods::VERSION).not_to be nil
  end
end
