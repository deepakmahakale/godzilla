# frozen_string_literal: true

require 'thor'
require 'wanda/sub_command_base'

module Wanda
  class Rails < SubCommandBase
    include Thor::Actions

    REQUIRED_RUBY = {
      # rails_version => required_ruby_version
      '6.2' => { required: '2.5.0', recommended: '3.0' },
      '6.1' => { required: '2.5.0', recommended: '3.0' },
      '6.0' => { required: '2.5.0', recommended: '2.6' },
      '5.2' => { required: '2.2.2', recommended: '2.5' },
      '5.1' => { required: '2.2.2', recommended: '2.5' },
      '5.0' => { required: '2.2.2', recommended: '2.4' },
      '4.2' => { required: '1.9.3', recommended: '2.2' }
    }.freeze

    desc 'upgrade [options]', 'rails upgrade'
    option :from, aliases: '-f'
    option :to,   aliases: '-t'
    option :project_directory, aliases: '-d'
    def upgrade
      case format_version(options[:to])
      when '5.2'
        rails4_2_to_5_2
      else
        puts set_color('WARN: Not supported', :red)
      end
    end

    private

    def rails4_2_to_5_2
      inside "#{options[:project_directory]}" do
        # https://rubydoc.info/github/wycats/thor/master/Thor/Actions#uncomment_lines-instance_method
        gsub_file 'Gemfile', /gem\s+["']+rails['"\s,]+([~>\s\d\.]+)/ do |match|
          match.gsub(/(~>\s*)*[\d\.]+/, latest_rails_version(options[:to]))
        end
        gsub_file 'Gemfile', /^\s*ruby\s+.?([\d\.]+(p\d+)?)/ do |match|
          match.gsub(/[\d\.]+(p\d+)?/, required_ruby_version(latest_rails_version(options[:to])))
        end
        gsub_file 'config/application.rb', /^.*active_record.raise_in_transactional_callbacks.*\n/, ''
        gsub_file 'config/application.rb', /^.*config.serve_static_assets.*\n/ do |match|
          match.gsub('serve_static_assets', 'public_file_server.enabled')
        end
        gsub_file 'config/application.rb', /^.*config.serve_static_files.*\n/ do |match|
          match.gsub('serve_static_files', 'public_file_server.enabled')
        end
        gsub_file 'config/application.rb', /^.*config.static_cache_control.*\n/ do |match|
          match.gsub(/(static_cache_control\s*=\s*)(.*)/) { "#{$1} { 'Cache-Control' => #{$2} }" }
        end
        gsub_file 'config/routes.rb', /^.*::Application.routes.draw.*\n/ do |match|
          match.gsub(/^\s*(.*::Application)/, 'Rails.application')
        end

        # TODO: Check if we should do this at bash level
        Dir.glob('app/controllers/*.rb') do |file_name|
          gsub_file file_name, /before_filter/ do |match|
            match.tr('before_filter', 'before_action')
          end
          gsub_file file_name, /skip_before_filter/ do |match|
            match.tr('skip_before_filter', 'skip_before_action')
          end
          gsub_file file_name, /redirect_to\(:back\)/ do |match|
            match.tr('redirect_to(:back)', 'redirect_back(fallback_location: root_path)')
          end
        end

        unless File.exist?('app/models/application_record.rb')
          create_file 'app/models/application_record.rb' do
            <<~STR
            class ApplicationRecord < ActiveRecord::Base
              self.abstract_class = true
            end
            STR
          end
        end

        Dir.glob('app/models/*.rb') do |file_name|
          next if file_name == 'app/models/application_record.rb'

          gsub_file file_name, /ActiveRecord::Base/ do |match|
            match.gsub('ActiveRecord::Base', 'ApplicationRecord')
          end
        end

        unless File.exist?('app/mailers/application_mailer.rb')
          create_file 'app/mailers/application_mailer.rb' do
            <<~STR
            class ApplicationMailer < ActionMailer::Base
              default from: "sample@\#{ActionMailer::Base.smtp_settings[:domain]}"
            end
            STR
          end
        end

        Dir.glob('app/mailers/*.rb') do |file_name|
          next if file_name == 'app/mailers/application_mailer.rb'

          gsub_file file_name, /ActionMailer::Base/ do |match|
            match.gsub('ActionMailer::Base', 'ApplicationMailer')
          end
        end

        Dir.glob('db/migrate/*.rb') do |file_name|
          gsub_file file_name, /ActiveRecord::Migration$/ do |match|
            match.gsub('ActiveRecord::Migration', 'ActiveRecord::Migration[4.2]')
          end
        end

        warning = <<~STR
          To ensure belongs_to associations work as they were in the previous
          version `config.active_record.belongs_to_required_by_default = \
          false` will be added to `config/application.rb`.
          Please enable this once you have tested the application with the new \
          behavior.
        STR
        puts set_color(warning, :red)
        insert_into_file "config/application.rb",
          :after => "Application < Rails::Application\n" do
          "    config.active_record.belongs_to_required_by_default = false\n"
        end

        run(
          <<~STR
            rubocop \
            --require rubocop-rspec \
            --only FactoryBot/AttributeDefinedStatically \
            --auto-correct \
            spec/factories/
          STR
        )

        run('rails5-spec-converter')
      end
    end

    def format_version(version)
      /\d.\d/.match(version)[0]
    end

    def latest_rails_version(version)
      case format_version(version)
      when '5.2'
        '5.2.6'
      end
    end

    def required_ruby_version(rails_version)
      REQUIRED_RUBY.dig(format_version(rails_version), :recommended)
    end
  end
end
