# frozen_string_literal: true

require 'thor'
require 'wanda/sub_command_base'
require 'wanda/rails'

module Wanda
  class Upgrade < SubCommandBase
    include Thor::Actions

    desc 'rails [options]', 'Rails upgrade'
    subcommand 'rails', Wanda::Rails
  end
end
