# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.2]

### Fixed
- Fixed license JSON format to comply with CycloneDX 1.6 specification. License text field now uses AttachedText object format, and URLs are properly placed in url field instead of text field.
([PR #92](https://github.com/CycloneDX/cyclonedx-cocoapods/pull/92))
([Issue #91](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/91)) [@flyingdog1310](https://github.com/flyingdog1310).

## [2.0.1]

### Fixed
- Fixed JSON output to use an integer for the bom file version number. ([Issue #89](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/89)) [@macblazer](https://github.com/macblazer).

## [2.0.0]

### Added
- Added JSON output if the specified `output` has a `.json` suffix. ([Issue #62](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/62)) [@jeremylong](https://github.com/jeremylong).
- Added CLI options to set manufacturer metadata about the component being scanned (five separate parameters). ([Issue #72](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/72)) [@jeremylong](https://github.com/jeremylong).
- Added CLI options to set the VCS URL and build URL of the component being scanned. ([PR #82](https://github.com/CycloneDX/cyclonedx-cocoapods/pull/82)) [@jeremylong](https://github.com/jeremylong).

### Changed
- Updated to use v1.6 of the CycloneDX specification. ([PR #81](https://github.com/CycloneDX/cyclonedx-cocoapods/pull/81)) [@jeremylong](https://github.com/jeremylong).
- Updated to use newer `tools` section elements. ([PR #80](https://github.com/CycloneDX/cyclonedx-cocoapods/pull/80)) [@jeremylong](https://github.com/jeremylong).
- Updated to use a purl for the `bom-ref` of the component being scanned.  When analyzing an app the purl will start with `pkg:generic`. ([PR #84](https://github.com/CycloneDX/cyclonedx-cocoapods/pull/84)) [@jeremylong](https://github.com/jeremylong).
- Changed the short `-b` CLI parameter to specify the build URL instead of the bom file version.  Use `--bom-version` to specify the bom file version if needed. ([PR #82](https://github.com/CycloneDX/cyclonedx-cocoapods/pull/82)) [@jeremylong](https://github.com/jeremylong).
- Changed the short `-s` CLI parameter to specify the source VCS URL instead of the shortened string lengths.  Use `--shortened-strings` to specify the max length of strings if needed. ([PR #82](https://github.com/CycloneDX/cyclonedx-cocoapods/pull/82)) [@jeremylong](https://github.com/jeremylong).

### Fixed
- Fixed XML output when Pod description contains a null byte. ([Issue #85](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/85)) [@fnxpt](https://github.com/fnxpt).

## [1.4.1]

### Changed
- Minimum Ruby version is now v2.6.3 so the [Array.union](https://apidock.com/ruby/v2_6_3/Array/union) function can be used.

### Fixed
- Improved performance when analyzing a Podfile with many pods. ([Issue #78](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/78)) [@macblazer](https://github.com/macblazer).

## [1.4.0]

### Added
- Added `evidence` element to the component output to indicate that we are doing manifest analysis to generate the bom. ([Issue #69](https://github.com/CycloneDX/cyclonedx-cocoapods/issues/69)) [@macblazer](https://github.com/macblazer).

### Fixed
- Added top level dependencies when the metadata/component is specified (by using the `--name`, `--version`, and `--type` parameters). ([PR #70](https://github.com/CycloneDX/cyclonedx-cocoapods/pull/70)) [@fnxpt](https://github.com/fnxpt)
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
