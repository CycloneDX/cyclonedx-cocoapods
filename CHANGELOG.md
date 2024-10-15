# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0]

### Added
- Added `evidence` element to the component output to indicate that we are doing manifest analisys to generate the bom. ([Issue #69](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/69)) [@macblazer](https://github.com/macblazer).

### Fixed
- Properly concatenate paths to Podfile and Podfile.lock (with unit tests!). ([Issue #71](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/71)) [@macblazer](https://github.com/macblazer).

## [1.3.0]

### Added
- Added optional `--shortened-strings` CLI parameter to limit the author, publisher, and purl lengths. ([Issue #65](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/65)) [@macblazer](https://github.com/macblazer).

### Changed
- Updated to use v1.5 of the CycloneDX specification. ([Issue #57](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/57)) [@macblazer](https://github.com/macblazer)
- Code cleanup based on [RuboCop](https://rubocop.org/) analysis. ([Issue #45](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/45)) [@macblazer](https://github.com/macblazer).

### Fixed
- Following the specification to put the `bom-ref` attribute on `component` instead of as a `bomRef` element of `component`. [@macblazer](https://github.com/macblazer).

## [1.2.0]

### Added
- Includes dependency relationship information for each of the components. ([Issue #58](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/58)) [@fnxpt](https://github.com/fnxpt).

### Changed
- Components and dependencies are output in alphabetically sorted order by `purl` to increase reproducability of BOM generation. ([Issue #59](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/59)) [@macblazer](https://github.com/macblazer).

## [1.1.2]

### Changed
- Updated gem dependency for cocoapods to be minimum v1.10.1 up to anything less than v2. ([Issue #51](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/51)) [@macblazer](https://github.com/macblazer).
- Updated gem dependency for nokogiri to be minimum v1.11.2 up to anything less than v2. [@macblazer](https://github.com/macblazer).
- Updated README.md with a description of what happens with pods or Podfiles that use subspecs. ([Issue #52](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/52)) [@macblazer](https://github.com/macblazer).

### Fixed
- Fixed parsing of a Podfile that uses CocoaPods plugins.  ([PR #55](https://github.com/CycloneDX/cyclonedx-cocoapods/pull/55)) [@DwayneCoussement](https://github.com/DwayneCoussement).

## [1.1.1]

### Changed
- Better error messaging when a problem is encountered while gathering pod information ([Issue #48](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/48)) [@macblazer](https://github.com/macblazer).

### Fixed
- Including a pod that has a platform-specific dependency for an unused platform no longer causes a crash ([Issue #46](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/46)) [@macblazer](https://github.com/macblazer).
- Analyzing a Podfile that has no pods defined in it no longer causes a crash [@macblazer](https://github.com/macblazer).

## [1.1.0]

### Added
- Can now eliminate Podfile targets that include "test" in their name ([Issue #43](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/43)) [@macblazer](https://github.com/macblazer).

## [1.0.0]

### Added
- Local pods now use the `file_name` purl qualifier ([Issue #11](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/11)) [@macblazer](https://github.com/macblazer).
- Gathering more info for local pods, Git based pods, and podspec based pods ([Issues #11](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/11), [#12](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/12), and [#13](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/13)) [@macblazer](https://github.com/macblazer).
- Added a small section in the README.md for contributors and how to set up for local development [@macblazer](https://github.com/macblazer).
- Added this CHANGELOG.md file [@macblazer](https://github.com/macblazer).

### Changed
- Removed the cyclonedx-cocoapods dependencies from the list of tools in the bom metadata ([Issue #29](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/29)) [@macblazer](https://github.com/macblazer).
- Changed copyright to OWASP Foundation ([Issue #36](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/36)) [@macblazer](https://github.com/macblazer).

## [0.1.1]

- Initial publication. [@jgongo](https://github.com/jgongo)
