# frozen_string_literal: true
require 'thor'
require 'wanda/rails'

# Ref: https://nandovieira.com/creating-generators-and-executables-with-thor
module Wanda
  # CLI implementation for wanda
  class CLI < Thor
    include Thor::Actions

    # Keep sorted list | except rails
    SUPPORTED_GEMS = {
      rails: [
        { from: 4.2, to: 5.2 },
        { from: 5.2, to: 6.0 }
      ]
    }.freeze

    def self.exit_on_failure?
      true
    end

    desc 'version', 'Display version'
    map %w[-v --version] => :version
    def version
      say "Wanda #{VERSION}"
    end

    desc 'rails', 'rails upgrade'
    subcommand "rails", Wanda::Rails

    # option :project_directory, aliases: '-d'
    # def upgrade(gem, *extras)
    #   klass = Object.const_get("Wanda::#{classify(gem)}")
    #   obj = klass.new(options)
    #   obj.rails4_2_to_5_2(extras)
    # end

    # desc 'list [options]', 'List supported gems'
    # def list
    #   message = <<~STR
    #     Supports upgrade for:
    #     #{'=' * 76}
    #         #{format_list}
    #   STR
    #   puts set_color(message, :green)
    # end

    private

    def classify(gem)
      gem.split('_').collect(&:capitalize).join
    end

    def format_list
      SUPPORTED_GEMS.map do |gem, versions|
        version_list = versions.map do |version|
          "#{version[:from]} => #{version[:to]}"
        end.join(', ')

        "#{gem}: " + version_list
      end.join("\n    ")
    end
  end
end
