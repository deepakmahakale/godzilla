# frozen_string_literal: true
require 'thor'
require 'wanda/rails'

# Ref: https://nandovieira.com/creating-generators-and-executables-with-thor
module Wanda
  # CLI implementation for wanda
  class CLI < Thor
    include Thor::Actions

    REQUIRED_RUBY = {
    # rails_version => required_ruby_version
      '6.2' => {
        required: '2.5.0',
        recommended: '3.0'
      },
      '6.1' => {
        required: '2.5.0',
        recommended: '3.0'
      },
      '6.0' => {
        required: '2.5.0',
        recommended: '2.6'
      },
      '5.2' => {
        required: '2.2.2',
        recommended: '2.5'
      },
      '5.1' => {
        required: '2.2.2',
        recommended: '2.5'
      },
      '5.0' => {
        required: '2.2.2',
        recommended: '2.4'
      },
      '4.2' => {
        required: '1.9.3',
        recommended: '2.2'
      }
    }.freeze

    def self.exit_on_failure?
      true
    end

    desc 'version', 'Display version'
    map %w[-v --version] => :version

    def version
      say "Wanda #{VERSION}"
    end

    desc 'upgrade GEM [options]', 'upgrade the gem'
    option :target, aliases: '-t'
    option :project_directory, aliases: '-d'
    def upgrade(gem, *options)
      puts '==='
      puts gem
      puts options
      puts '==='
      invoke 'wanda:rails:sad', :aa => options

      # klass = Object.const_get("Wanda::#{classify(gem)}")
      # klass.upgrade(options)
    end

    desc 'list [options]', 'list of supported gems'
    def list(*options)
      puts '
      - rails
      '
    end

    private

    def required_ruby_version(rails_version)
      REQUIRED_RUBY.dig(rails_version, :recommended)
    end

    def classify(gem)
      gem.split('_').collect(&:capitalize).join
    end
  end
end
