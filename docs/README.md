---
layout: default
title: Home
nav_order: 1
description: Home page
permalink: /
---

# Wanda
Upgrade Rails with one command

```bash
$ wanda upgrade rails --to 5.2

Checking for deprecated config in application.rb
Checking for deprecated *_filter callbacks in controllers
Models now inherit from ApplicationRecord
Mailers now inherit from ApplicationMailer
Add rails version to database migrations
To ensure belongs_to associations work as they were in the previous
version `config.active_record.belongs_to_required_by_default = false` will be added to `config/application.rb`.
Please enable this once you have tested the application with the new behavior.
      insert  config/application.rb
Changing static factory attributes
         run  rubocop --require rubocop-rspec --only FactoryBot/AttributeDefinedStatically --auto-correct spec/factories/
 from "."
Converting controller specs
         run  rails5-spec-converter from "."
Checking for ruby version requirements
Changing the rails version
```
## Usage

```bash
Usage:
  wanda upgrade rails [options]

Options:
  -f, [--from=FROM]                            # Run `wanda list` to get list of supported versions
  -t, --to=TO                                  # Run `wanda list` to get list of supported versions
  -d, [--project-directory=PROJECT_DIRECTORY]
  -r, [--recommended], [--no-recommended]      # Upgrade to recommended ruby version.
                                               # Using --no-recommended will only upgrade the ruby to minimum required version
                                               # Default: true
  -b, [--source-branch=SOURCE_BRANCH]          # From where to checkout the new branch. Default is current branch
      [--target-branch=TARGET_BRANCH]          # New branch name
                                               # Default: wanda/rails_upgrade

Rails upgrade
```
