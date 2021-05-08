# frozen_string_literal: true

require 'thor'
require 'wanda/sub_command_base'
require 'wanda/rails'
require 'wanda/list'

module Wanda
  class Upgrade < SubCommandBase
    include Thor::Actions

    # register(klass, subcommand_name, usage, description, options = {})
    #      desc usage, description, options
    #
    register(Wanda::Rails, 'rails', 'rails [options]', Wanda::Rails.desc)
    tasks["rails"].options = Wanda::Rails.class_options

    register(Wanda::List, 'list', 'list [options]', Wanda::List.desc)
    tasks["list"].options = Wanda::List.class_options
  end
end
