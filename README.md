[![Build Status](https://github.com/CycloneDX/cyclonedx-cocoapods/workflows/Xcode%20CI/badge.svg)](https://github.com/CycloneDX/cyclonedx-cocoapods/actions?workflow=Xcode+CI)
[![Gem Version](https://badge.fury.io/rb/cyclonedx-cocoapods.svg)](https://badge.fury.io/rb/cyclonedx-cocoapods)
[![License](https://img.shields.io/badge/license-Apache%202.0-brightgreen.svg)][License]
[![Website](https://img.shields.io/badge/https://-cyclonedx.org-blue.svg)](https://cyclonedx.org/)
[![Slack Invite](https://img.shields.io/badge/Slack-Join-blue?logo=slack&labelColor=393939)](https://cyclonedx.org/slack/invite)
[![Group Discussion](https://img.shields.io/badge/discussion-groups.io-blue.svg)](https://groups.io/g/CycloneDX)
[![Twitter](https://img.shields.io/twitter/url/http/shields.io.svg?style=social&label=Follow)](https://twitter.com/CycloneDX_Spec)


# CycloneDX CocoaPods (Objective-C/Swift)

The CycloneDX CocoaPods Gem creates a valid CycloneDX bill-of-material document from all project dependencies. CycloneDX is a lightweight BoM specification that is easily created, human readable, and simple to parse.

## Installing from RubyGems

```shell
% gem install cyclonedx-cocoapods
```

## Building and Installing From Source

```shell
gem build cyclonedx-cocoapods.gemspec
gem install cyclonedx-cocoapods-x.x.x.gem
```

## Usage
Usage: `cyclonedx-cocoapods` [options]

        --[no-]verbose               Run verbosely
    -p, --path path                  (Optional) Path to CocoaPods project directory, current directory if missing
    -o, --output bom_file_path       (Optional) Path to output the bom.xml file to
    -b, --bom-version bom_version    (Optional) Version of the generated BOM, 1 if not provided
    -g, --group group                (Optional) Group of the component for which the BOM is generated
    -n, --name name                  (Optional, if specified version and type are also required) Name of the component for which the BOM is generated
    -v, --version version            (Optional) Version of the component for which the BOM is generated
    -t, --type type                  (Optional) Type of the component for which the BOM is generated (one of application|framework|library|container|operating-system|device|firmware|file)
    -h, --help                       Show help message

**Output:** BoM file at specified location, `./bom.xml` if not specified

### Example

```shell
% cyclonedx-cocoapods --path /path/to/cocoapods/project --output /path/to/bom.xml --version 6 
```

#### Specific example

This repo contains a file named `example_bom.xml` that was generated with this tool.

It represents the open source [PodsUpdater application](https://github.com/kizitonwose/PodsUpdater).  The PodsUpdater code was checked out,
then these two commands were run in the checked out code directory.

```shell
% pod install
% cyclonedx-cocoapods -n "kizitonwose/PodsUpdater" -v 1.0.3 -t application --output example_bom.xml
```


## Copyright & License
Permission to modify and redistribute is granted under the terms of the Apache 2.0 license. See the [LICENSE] file for the full license.

[License]: https://github.com/CycloneDX/cyclonedx-cocoapods/blob/master/LICENSE