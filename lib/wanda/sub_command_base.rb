# frozen_string_literal: true

class SubCommandBase < Thor
  def self.banner(command, _namespace = nil, _subcommand = false)
    "#{basename} #{subcommand_prefix} #{command.usage}"
  end

  def self.subcommand_prefix
    name
      .gsub(/.*::/, '')
      .gsub(/^[A-Z]/) { |match| match[0].downcase }
      .gsub(/[A-Z]/)  { |match| "-#{match[0].downcase}" }
  end
end
