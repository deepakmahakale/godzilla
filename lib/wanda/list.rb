# frozen_string_literal: true

require 'thor'
require 'thor/group'

module Wanda
  class List < Thor::Group
    include Thor::Actions

    desc 'List supported gems'

    # Keep sorted list | except rails
    SUPPORTED_GEMS = {
      rails: [
        { from: 4.2, to: 5.2 },
        { from: 5.2, to: 6.0 }
      ]
    }.freeze

    def list
      message = <<~STR
        Supports upgrade for:
        #{'=' * 76}
            #{format_list}
      STR
      puts set_color(message, :green)
    end

    def self.exit_on_failure?
      true
    end

    private

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
