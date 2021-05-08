# Wanda

[![Gem Version](https://badge.fury.io/rb/wanda.svg)](https://badge.fury.io/rb/wanda)

Wanda helps you upgrade your rails application with minimal inputs.

When you upgrade the application it will be upgraded with the recommended versions
of ruby and rails.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wanda'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install wanda

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

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake test` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/deepakmahakale/wanda.
This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the
[code of conduct](https://github.com/deepakmahakale/wanda/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Wanda project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/deepakmahakale/wanda/blob/master/CODE_OF_CONDUCT.md).
