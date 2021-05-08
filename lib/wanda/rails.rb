# frozen_string_literal: true

require 'thor'
require 'thor/group'

module Wanda
  class Rails < Thor::Group
    include Thor::Actions

    desc 'Rails upgrade'
    class_option :from, aliases: '-f',
      desc: "Run `wanda list` to get list of supported versions"
    class_option :to, aliases: '-t', required: true,
      desc: 'Run `wanda list` to get list of supported versions'
    class_option :project_directory, aliases: '-d'
    class_option :recommended, aliases: '-r', type: :boolean, default: true,
      desc: <<~DESC
      Upgrade to recommended ruby version. \
      Using --no-recommended will only upgrade the ruby to minimum required version
      DESC
    class_option :source_branch, aliases: '-b', # default: 'master',
      desc: 'From where to checkout the new branch. Default is current branch'
    class_option :target_branch, default: 'wanda/rails_upgrade',
      desc: 'New branch name'

    DEFAULT_GIT_MESSAGE = "Changes for upgrading rails application".freeze

    REQUIRED_RUBY = {
      # rails_version => required_ruby_version
      '6.2' => { required: '2.5.0', recommended: '3.0' },
      '6.1' => { required: '2.5.0', recommended: '3.0' },
      '6.0' => { required: '2.5.0', recommended: '2.6' },
      '5.2' => { required: '2.2.2', recommended: '2.5' },
      '5.1' => { required: '2.2.2', recommended: '2.5' },
      '5.0' => { required: '2.2.2', recommended: '2.4' },
      '4.2' => { required: '1.9.3', recommended: '2.2' },
    }.freeze

    LATEST_RAILS_VERSIONS = {
      '5.2' => '5.2.4.6',
    }.freeze

    def upgrade
      case format_version(options[:to])
      when '5.2'
        rails4_2_to_5_2
      else
        puts set_color('WARN: Not supported', :red)
      end
    end

    def self.exit_on_failure?
      false
    end

    private

    def rails4_2_to_5_2
      inside options[:project_directory].to_s do
        # https://rubydoc.info/github/wycats/thor/master/Thor/Actions#uncomment_lines-instance_method
        # change_git_branch
        remove_application_name_from_routes
        application_config_changes
        change_deprecated_filter_to_action
        inherit_from_application_record
        inherit_from_application_mailer
        add_version_to_database_migrations
        disable_belongs_to_required
        change_static_factory_attributes
        convert_controller_specs
        # Avoid bundle issues due to version changes
        change_ruby_version
        change_rails_version
        # git_commit(DEFAULT_GIT_MESSAGE)
      end
    end

    def change_git_branch
      say "Creating a new branch #{options[:target_branch]} from #{options[:source_branch] || 'current branch'}", :green
      run("git branch #{options[:target_branch]} #{options[:source_branch]}")
      run("git checkout #{options[:target_branch]}")
    end

    def git_commit(message, add: true)
      say 'Adding a git commit', :green
      run('git add .') if add
      run("git commit -m '#{message}'")
    end

    def change_rails_version
      say 'Changing the rails version', :green
      silently_gsub_file 'Gemfile', /gem\s+["']+rails['"\s,]+([~>\s\d\.]+)/ do |match|
        match.gsub(/(~>\s*)*[\d\.]+/, latest_rails_version(options[:to]))
      end
    end

    def change_ruby_version
      say 'Checking for ruby version requirements', :green
      silently_gsub_file 'Gemfile', /^\s*ruby\s+.?([\d\.]+(p\d+)?)/ do |match|
        current_version = match.match(/([\d\.]+(p[\d]+)?)/)[1]
        required_version = required_ruby_version(
          latest_rails_version(options[:to])
        )
        # Add flag to upgrade ruby to recommended
        # Default: upgrade to required ruby
        match.gsub(/[\d\.]+(p\d+)?/, latest_version(current_version, required_version))
      end
      if File.exist?('.ruby-version')
        silently_gsub_file '.ruby-version', /^\s*(ruby\-)?([\d\.]+(p\d+)?)/ do |match|
          current_version = match.match(/([\d\.]+(p[\d]+)?)/)[1]
          required_version = required_ruby_version(
            latest_rails_version(options[:to])
            )
          match.gsub(/[\d\.]+(p\d+)?/, latest_version(current_version, required_version))
        end
      end
    end

    def remove_application_name_from_routes
      silently_gsub_file 'config/routes.rb', /^.*::Application.routes.draw.*\n/ do |match|
        match.gsub(/^\s*(.*::Application)/, 'Rails.application')
      end
    end

    def application_config_changes
      say 'Checking for deprecated config in application.rb', :green
      silently_gsub_file 'config/application.rb', /^.*active_record.raise_in_transactional_callbacks.*\n/, "\n"
      silently_gsub_file 'config/application.rb', /^.*config.serve_static_assets.*\n/ do |match|
        match.gsub('serve_static_assets', 'public_file_server.enabled')
      end
      silently_gsub_file 'config/application.rb', /^.*config.serve_static_files.*\n/ do |match|
        match.gsub('serve_static_files', 'public_file_server.enabled')
      end
      silently_gsub_file 'config/application.rb', /^.*config.static_cache_control.*\n/ do |match|
        match.gsub(/(static_cache_control\s*=\s*)(.*)/) { "#{Regexp.last_match(1)} { 'Cache-Control' => #{Regexp.last_match(2)} }" }
      end
    end

    def change_deprecated_filter_to_action
      # TODO: Check if we should do this at bash level
      say 'Checking for deprecated *_filter callbacks in controllers', :green
      Dir.glob('app/controllers/*.rb') do |file_name|
        silently_gsub_file file_name, /before_filter/ do |match|
          match.gsub('before_filter', 'before_action')
        end
        silently_gsub_file file_name, /skip_before_filter/ do |match|
          match.gsub('skip_before_filter', 'skip_before_action')
        end
        silently_gsub_file file_name, /redirect_to\(:back\)/ do |match|
          match.gsub('redirect_to(:back)', 'redirect_back(fallback_location: root_path)')
        end
      end
    end

    def inherit_from_application_record
      unless File.exist?('app/models/application_record.rb')
        # Change this to copy_file
        say 'Creating a new file at app/models/application_record.rb', :green
        create_file 'app/models/application_record.rb' do
          <<~STR
            class ApplicationRecord < ActiveRecord::Base
              self.abstract_class = true
            end
          STR
        end
      end

      say 'Models now inherit from ApplicationRecord', :green
      Dir.glob('app/models/*.rb') do |file_name|
        next if file_name == 'app/models/application_record.rb'

        silently_gsub_file file_name, /ActiveRecord::Base/ do |match|
          match.gsub('ActiveRecord::Base', 'ApplicationRecord')
        end
      end
    end

    def inherit_from_application_mailer
      unless File.exist?('app/mailers/application_mailer.rb')
        # Change this to copy_file
        say 'Creating a new file at app/mailers/application_mailer.rb', :green
        create_file 'app/mailers/application_mailer.rb' do
          <<~STR
            class ApplicationMailer < ActionMailer::Base
              default from: "sample@\#{ActionMailer::Base.smtp_settings[:domain]}"
            end
          STR
        end
      end

      say 'Mailers now inherit from ApplicationMailer', :green
      Dir.glob('app/mailers/*.rb') do |file_name|
        next if file_name == 'app/mailers/application_mailer.rb'

        silently_gsub_file file_name, /ActionMailer::Base/ do |match|
          match.gsub('ActionMailer::Base', 'ApplicationMailer')
        end
      end
    end

    def add_version_to_database_migrations
      say 'Add rails version to database migrations', :green
      Dir.glob('db/migrate/*.rb') do |file_name|
        silently_gsub_file file_name, /ActiveRecord::Migration$/ do |match|
          match.gsub('ActiveRecord::Migration', 'ActiveRecord::Migration[4.2]')
        end
      end
    end

    def disable_belongs_to_required
      warning = <<~STR
        To ensure belongs_to associations work as they were in the previous
        version `config.active_record.belongs_to_required_by_default = \
        false` will be added to `config/application.rb`.
        Please enable this once you have tested the application with the new \
        behavior.
      STR
      say warning, :red
      insert_into_file 'config/application.rb',
                      after: "Application < Rails::Application\n" do
        "    config.active_record.belongs_to_required_by_default = false\n"
      end
    end

    def change_static_factory_attributes
      say 'Changing static factory attributes', :green
      command = <<~STR
        rubocop \
        --require rubocop-rspec \
        --only FactoryBot/AttributeDefinedStatically \
        --auto-correct \
        spec/factories/
      STR
      run(command, capture: true)
    end

    def convert_controller_specs
      say 'Converting controller specs', :green
      run('rails5-spec-converter', capture: true)
    end

    # ==========================================================================

    def silently_gsub_file(path, flag, *args, &block)
      args.push(verbose: false)
      gsub_file(path, flag, *args, &block)
    end

    def format_version(version)
      /\d.\d/.match(version)[0]
    end

    def latest_rails_version(version)
      LATEST_RAILS_VERSIONS[format_version(version)]
    end

    def required_ruby_version(rails_version)
      ruby_version = options[:recommended] ? :recommended : :required
      REQUIRED_RUBY.dig(format_version(rails_version), ruby_version)
    end

    # Returns latest version
    # Add test case for this one including pre/rc/beta/alpha
    def latest_version(*versions)
      versions.sort_by { |v| Gem::Version.new(v) }.last
    end

    # Returns latest version
    # Add test case for this one including pre/rc/beta/alpha
    def latest_version(*versions)
      versions.sort_by { |v| Gem::Version.new(v) }.last
    end
  end
end
