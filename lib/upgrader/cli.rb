# frozen_string_literal: true

require 'optparse'
require 'thor'
# require 'thor/group'

Options = Struct.new(
  :current_ruby, :current_rails, :target_ruby, :target_rails, :project_directory
)
module Upgrader
  # CLI implementation for upgrader
  class CLI
    extend Thor::Actions
    # rubocop:disable Metrics/MethodLength(RuboCop)
    def self.start
      args = Options.new

      OptionParser.new do |opts|
        opts.banner = 'Usage: upgrader [options]'
        # opts.version = Upgrader::VERSION

        opts.on('-tVERSION', '--target=VERSION', 'Target rails version') do |version|
          args.target_rails = version
        end

        opts.on('-dDIRECTORY', '--directory=DIRECTORY', 'Rails project directory') do |dir|
          args.project_directory = dir
        end

        opts.separator 'Common options:'

        opts.on_tail('-v', '--version', 'Show version number and quit') do
          puts Upgrader::VERSION
          exit
        end
        opts.on_tail('-h', '--help', 'Show this help message and quit') do
          puts opts
          exit
        end
      end.parse!

      process(args)
    end
    # rubocop:enable Metrics/MethodLength(RuboCop)

    def self.process(args)
      # get_required_details(args)
      # upgrade(args)
      puts args
      copy_licence
    end

    def self.get_required_details(args)
      if args.current_ruby.nil?
        args.current_ruby = RUBY_VERSION
      end
      if args.target_ruby.nil?
        args.target_ruby = '2.7'
      end
      if args.current_rails.nil?
        args.current_rails = '5.0'
      end
      if args.target_rails.nil?
        args.target_rails = '6.0'
      end
    end

    def self.upgrade(args)
      puts args
      copy_licence
    end
    def self.copy_licence
      puts 'uncommenting line'
      uncomment_lines "test/sample.rb", /commented/
      create_file "test/sam2.rb"
    end
  end
end
