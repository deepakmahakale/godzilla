# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

Major changes in 0.0.2.beta

### Breaking changes
- Move upgrade as a subcommand
- Nested rails as a subcommand under upgrade

      before: wanda rails upgrade [options]
      after:  wanda upgrade rails [options]

### Added
- Added support to change git branch and perform changes
- Added support to commit the changes
- Added support for changing version in `.ruby-version` file if exists

### Changed
- Change minimum required version for rails5-spec-converter, rubocop-rspec and thor
- Move list as a subcommand

### Fixed
- Do not change the ruby version if it's already greater than the required version

## [0.0.1.beta] - 2021-05-07

### Added

- Rails upgrade support from 4.2 to 5.2
