# frozen_string_literal: true

require 'optparse'
require 'thor'

# Ref: https://nandovieira.com/creating-generators-and-executables-with-thor
module Upgrader
  # CLI implementation for upgrader
  class CLI < Thor
    include Thor::Actions
    def self.exit_on_failure?
      true
    end

    desc 'version', 'Display version'
    map %w[-v --version] => :version

    def version
      say "Upgrader #{VERSION}"
    end

    desc 'rails4_2_to_5_2', 'upgrade rails'
    option :target_rails, aliases: '-t'
    option :project_directory, aliases: '-d'
    def rails4_2_to_5_2
      inside "#{options[:project_directory]}" do
        # https://rubydoc.info/github/wycats/thor/master/Thor/Actions#uncomment_lines-instance_method
        gsub_file "Gemfile", /gem\s+["']+rails['"\s,]+([~>\s\d\.]+)/ do |match|
          # match.gsub(/[\d\.]+/, options[:target_rails])
          match.gsub(/(~>\s*)*[\d\.]+/, '5.2.4')
        end
        gsub_file "config/application.rb", /^.*active_record.raise_in_transactional_callbacks.*\n/, ''
        gsub_file "config/application.rb", /^.*config.serve_static_assets.*\n/ do |match|
          match.gsub('serve_static_assets', 'public_file_server.enabled')
        end
        gsub_file "config/application.rb", /^.*config.serve_static_files.*\n/ do |match|
          match.gsub('serve_static_files', 'public_file_server.enabled')
        end
        gsub_file "config/application.rb", /^.*config.static_cache_control.*\n/ do |match|
          match.gsub(/(static_cache_control\s*=\s*)(.*)/) { "#{$1} { 'Cache-Control' => #{$2} }" }
        end
        gsub_file "config/routes.rb", /^.*::Application.routes.draw.*\n/ do |match|
          match.gsub(/^\s*(.*::Application)/, 'Rails.application')
        end

        # TODO: Check if we should do this at bash level
        Dir.glob("app/controllers/*.rb") do |file_name|
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

        Dir.glob("app/models/*.rb") do |file_name|
          gsub_file file_name, /ActiveRecord::Base/ do |match|
            match.gsub('ActiveRecord::Base', 'ApplicationRecord')
          end
        end

        # We dont want to replace ActiveRecord::Base from this file hence creating
        # after replacing in all files
        unless File.exist?("app/models/application_record.rb")
          create_file "app/models/application_record.rb" do
            <<~STR
            class ApplicationRecord < ActiveRecord::Base
              self.abstract_class = true
            end
            STR
          end
        end

        unless File.exist?("app/mailers/application_mailer.rb")
          create_file "app/mailers/application_mailer.rb" do
            <<~STR
            class ApplicationMailer < ActionMailer::Base
              default from: "sample@\#{ActionMailer::Base.smtp_settings[:domain]}"
            end
            STR
          end
        end
        Dir.glob("app/mailers/*.rb") do |file_name|
          gsub_file file_name, /ActionMailer::Base/ do |match|
            match.gsub('ActionMailer::Base', 'ApplicationMailer')
          end
        end

        Dir.glob("db/migrate/*.rb") do |file_name|
          gsub_file file_name, /ActiveRecord::Migration$/ do |match|
            match.gsub('ActiveRecord::Migration', 'ActiveRecord::Migration[4.2]')
          end
        end

        insert_into_file "config/application.rb",
          :after => "Application < Rails::Application\n" do

          warning = <<~STR
            To ensure belongs_to associations doesn't break,
            `config.active_record.belongs_to_required_by_default \
            = false` will be added to `config/application.rb`.
            Please enable this once you have tested \
            the application with the new behaviour.
          STR
          puts set_color(warning, :red)
          # if yes? "To ensure belongs_to associations don't break adding `belongs_to_required_by_default`. press y/N"
            "    config.active_record.belongs_to_required_by_default = false\n"
          # else
            # ''
          # end
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
      end

      run("cd #{options[:project_directory]} && rails5-spec-converter")
    end
  end
end
