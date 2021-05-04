# frozen_string_literal: true

require 'optparse'
require 'thor'

# Ref: https://nandovieira.com/creating-generators-and-executables-with-thor
module Upgrader
  # CLI implementation for upgrader
  class CLI < Thor
    include Thor::Actions
    desc 'version', 'Display version'
    map %w[-v --version] => :version

    def version
      say "Upgrader #{VERSION}"
    end

    desc 'rails4_2_to_5_2', 'upgrade rails'
    option :target_rails, aliases: '-t'
    option :project_directory, aliases: '-d'
    def rails4_2_to_5_2
      # https://rubydoc.info/github/wycats/thor/master/Thor/Actions#uncomment_lines-instance_method
      gsub_file "#{options[:project_directory]}/Gemfile", /gem\s+["']+rails['"\s,]+([\d\.]+)/ do |match|
        # match.gsub(/[\d\.]+/, options[:target_rails])
        match.gsub(/[\d\.]+/, '5.2.4')
      end
      gsub_file "#{options[:project_directory]}/config/application.rb", /^.*active_record.raise_in_transactional_callbacks.*\n/, ''
      gsub_file "#{options[:project_directory]}/config/application.rb", /^.*config.serve_static_assets.*\n/ do |match|
        match.gsub('serve_static_assets', 'public_file_server.enabled')
      end
      gsub_file "#{options[:project_directory]}/config/application.rb", /^.*config.serve_static_files.*\n/ do |match|
        match.gsub('serve_static_files', 'public_file_server.enabled')
      end
      gsub_file "#{options[:project_directory]}/config/application.rb", /^.*config.static_cache_control.*\n/ do |match|
        match.gsub(/(static_cache_control\s*=\s*)(.*)/) { "#{$1} { 'Cache-Control' => #{$2} }" }
      end
      gsub_file "#{options[:project_directory]}/config/routes.rb", /^.*::Application.routes.draw.*\n/ do |match|
        match.gsub(/^\s*(.*::Application)/, 'Rails.application')
      end

      # TODO: Check if we should do this at bash level
      Dir.glob("#{options[:project_directory]}/app/controllers/*.rb") do |file_name|
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

      unless File.exist?("#{options[:project_directory]}app/models/application_record.rb")
        create_file "#{options[:project_directory]}/app/models/application_record.rb" do
          <<~STR
          class ApplicationRecord < ActiveRecord::Base
            self.abstract_class = true
          end
          STR
        end
      end
      Dir.glob("#{options[:project_directory]}/app/models/*.rb") do |file_name|
        gsub_file file_name, /ActiveRecord::Base/ do |match|
          match.gsub('ActiveRecord::Base', 'ApplicationRecord')
        end
      end

      unless File.exist?("#{options[:project_directory]}/app/mailers/application_mailer.rb")
        create_file "#{options[:project_directory]}/app/mailers/application_mailer.rb" do
          <<~STR
          class ApplicationMailer < ActionMailer::Base
            default from: "sample@\#{ActionMailer::Base.smtp_settings[:domain]}"
          end
          STR
        end
      end
      Dir.glob("#{options[:project_directory]}/app/mailers/*.rb") do |file_name|
        gsub_file file_name, /ActionMailer::Base/ do |match|
          match.gsub('ActionMailer::Base', 'ApplicationMailer')
        end
      end

      Dir.glob("#{options[:project_directory]}/db/migrate/*.rb") do |file_name|
        gsub_file file_name, /ActiveRecord::Migration$/ do |match|
          match.gsub('ActiveRecord::Migration', 'ActiveRecord::Migration[4.2]')
        end
      end

      insert_into_file "#{options[:project_directory]}/config/application.rb",
        :after => "Application < Rails::Application\n" do

        if yes? "To ensure belongs_to associations don't break adding `belongs_to_required_by_default`. press y/N"
          "    config.active_record.belongs_to_required_by_default = false\n"
        else
          ''
        end
      end

      run(
        <<~STR
          rubocop \
          --require rubocop-rspec \
          --only FactoryBot/AttributeDefinedStatically \
          --auto-correct \
          #{options[:project_directory]}/spec/factories/
        STR
      )

      run('cd #{options[:project_directory]} && rails5-spec-converter')
    end
  end
end
