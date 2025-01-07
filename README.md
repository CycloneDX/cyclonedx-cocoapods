[![Build Status](https://github.com/CycloneDX/cyclonedx-cocoapods/actions/workflows/ruby.yml/badge.svg)](https://github.com/CycloneDX/cyclonedx-cocoapods/actions/workflows/ruby.yml)
[![Gem Version](https://badge.fury.io/rb/cyclonedx-cocoapods.svg)](https://badge.fury.io/rb/cyclonedx-cocoapods)
[![License](https://img.shields.io/badge/license-Apache%202.0-brightgreen.svg)][License]
[![Website](https://img.shields.io/badge/https://-cyclonedx.org-blue.svg)](https://cyclonedx.org/)
[![Slack Invite](https://img.shields.io/badge/Slack-Join-blue?logo=slack&labelColor=393939)](https://cyclonedx.org/slack/invite)
[![Group Discussion](https://img.shields.io/badge/discussion-groups.io-blue.svg)](https://groups.io/g/CycloneDX)
[![Twitter](https://img.shields.io/twitter/url/http/shields.io.svg?style=social&label=Follow)](https://twitter.com/CycloneDX_Spec)


# CycloneDX CocoaPods (Objective-C/Swift)

The CycloneDX CocoaPods Gem creates a valid CycloneDX software bill-of-material document from all
[CocoaPods](https://cocoapods.org/) project dependencies. CycloneDX is a lightweight BOM specification
that is easily created, human readable, and simple to parse.

## Installation

### From RubyGems

```shell
% gem install cyclonedx-cocoapods
```

### From Source

First, clone/copy the source code from GitHub.  Then in the source code directory run these
commands (substituting the actual version number for `x.x.x`):

```shell
gem build cyclonedx-cocoapods.gemspec
gem install cyclonedx-cocoapods-x.x.x.gem
```

Building from source requires Ruby 2.6.3 or newer.

## Compatibility

*cyclonedx-cocoapods* aims to produce SBOMs according to the latest CycloneDX specification, which currently is [1.6](https://cyclonedx.org/docs/1.6/xml/).
You can use the [CycloneDX CLI](https://github.com/CycloneDX/cyclonedx-cli#convert-command) to convert between multiple BOM formats or specification versions.

## Usage
```
Generates a BOM with the given parameters. BOM component metadata is only generated if the component's name, version, and type are provided using the --name, --version, and --type parameters.
[version <version_number>]

USAGE
  cyclonedx-cocoapods [options]

OPTIONS
        --[no-]verbose               Show verbose debugging output
    -h, --help                       Show help message

  BOM Generation
    -p, --path path                  Path to CocoaPods project directory (default: current directory)
    -o, --output bom_file_path       Path to output the bom file to (default: "bom.xml"); if a *.json file is specified the output format will be JSON
        --bom-version bom_version    Version of the generated BOM (default: "1")
    -x, --exclude-test-targets       Eliminate Podfile targets whose name contains the word "test"
        --shortened-strings length   Trim author, publisher, and purl to <length> characters; this may cause data loss but can improve compatibility with other systems

  Component Metadata
  If a podspec file is present the name, version, and type do not need to be specified as they will be set automatically.
    -n, --name name                  (If specified version and type are also required) Name of the component for which the BOM is generated
    -v, --version version            Version of the component for which the BOM is generated
    -t, --type type                  Type of the component for which the BOM is generated (one of application|framework|library|container|operating-system|device|firmware|file)
    -g, --group group                Group of the component for which the BOM is generated
    -s, --source source_url          Optional: The version control system URL of the component for the BOM is generated
    -b, --build build_url            Optional: The build URL of the component for which the BOM is generated

  Manufacturer Metadata
        --manufacturer-name name     Name of the manufacturer
        --manufacturer-url url       URL of the manufacturer
        --manufacturer-contact-name name
                                     Name of the manufacturer contact
        --manufacturer-email email   Email of the manufacturer contact
        --manufacturer-phone phone   Phone number of the manufacturer contact
```

**Output:** BOM file at specified location, `./bom.xml` if not specified

### Example

```shell
% cyclonedx-cocoapods --path /path/to/cocoapods/project --output /path/to/bom.xml --version 6
```

#### Specific example

This repo contains files named `example_bom.xml` and `example_bom.json` that were generated with this tool.

They represent the open source [PodsUpdater application](https://github.com/kizitonwose/PodsUpdater).  The PodsUpdater
code was checked out, then these threee commands were run in the checked out code directory.

```shell
% pod install
% cyclonedx-cocoapods -n "kizitonwose-PodsUpdater" -v 1.0.3 -t application -s https://github.com/kizitonwose/PodsUpdater --output example_bom.xml
% cyclonedx-cocoapods -n "kizitonwose-PodsUpdater" -v 1.0.3 -t application -s https://github.com/kizitonwose/PodsUpdater --output example_bom.json
```

The JSON file here has also been run through a JSON formatter for easier reading by humans.  The original JSON
output is one long line with no extra whitespace - great for computers, but difficult for humans.

### A Note About CocoaPod Subspecs

Many CocoaPods make use of [subspec functionality](https://guides.cocoapods.org/syntax/podspec.html#subspec).
Podfiles can require whole pods, or just subspecs; pods themselves may require whole pods or subspecs of other
pods.  In complex projects such as React Native apps this often results in a single pod being included as a
dependency multiple times as several of its subspecs are included individually.

*cyclonedx-cocoapods* works properly with this, and adds a dependency in the BOM output for each subspec that is
required by the Podfile and throughout the chain of dependencies.  Each subspec will only appear once in the BOM
file.  This gives you granular detail in the BOM of which subspecs of which pods are used.  This is easiest seen
with an example.

The Podfile
```ruby
target 'SampleProject' do
  pod 'SamplePod/firstsubspec'
  pod 'SamplePod/secondsubspec'
end
```

If the SamplePod is at v2.1, running *cyclonedx-cocoapods* on this will output a BOM file with two `component`
dependencies:
- `pkg:cocoapods/SamplePod@2.1#firstsubspec` at `https://github.com/example/SamplePod`
- `pkg:cocoapods/SamplePod@2.1#secondsubspec` at `https://github.com/example/SamplePod`

[Dependency Track](https://dependencytrack.org) (DT) is a tool that many organizations use to help automate SBOM
related tasks.  When uploading an SBOM that contains multiple subspecs from the same pod, or a single subspec
alongside the complete pod dependency, the initial upload will indicate a number of dependencies equal to the number
of `component` objects within the BOM.  However, DT analysis then looks for unique repositories in use which will
merge all of the subspecs of a particular pod into a single entry.  On later uploads to DT of the same or similar BOM
it will indicate just the number of unique repositories.

Uploading the above SamplePod BOM file to DT will initially see two dependencies.  Later analysis by DT notices
that both dependencies resolve to the same repository, so DT will then only show a single dependency.

## Contributing

To set up for local development, make a fork of this repo, make a branch on your fork named after the issue or workflow you are improving, checkout your branch, then run `bundle install`.

### Right to Contribute

This project runs the [DCO](https://probot.github.io/apps/dco/) checker to validate that the code author has the right to submit the code they are
contributing to the project.  Please verify that you do have the right to contribute, then when running `git commit` add the `-s` flag to
automatically add the proper `Signed-off-by` line to the commit message.

### Pull requests

Before submitting your pull request, please do the following:

- Run `rake spec` and make sure all the tests pass. If you are adding new commands or features, they must include tests. If you are changing functionality, update the tests or add new tests as needed.
- Add a note to the CHANGELOG describing what you changed.
- Make your pull request. If it is related to an issue, add a link to the issue in the description.

## Copyright & License
Permission to modify and redistribute is granted under the terms of the Apache 2.0 license. See the [LICENSE] file for the full license.

[License]: https://github.com/CycloneDX/cyclonedx-cocoapods/blob/master/LICENSE
