# frozen_string_literal: true

require 'thor'
require 'wanda/upgrade'

# Ref: https://nandovieira.com/creating-generators-and-executables-with-thor
module Wanda
  # CLI implementation for wanda
  class CLI < Thor
    include Thor::Actions

    desc 'version', 'Display version'
    map %w[-v --version] => :version
    def version
      say "Wanda #{VERSION}"
    end

    desc 'upgrade [GEM]', 'Upgrade gem'
    subcommand 'upgrade', Wanda::Upgrade

    def self.exit_on_failure?
      true
    end
  end
end
