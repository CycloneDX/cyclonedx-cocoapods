# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
