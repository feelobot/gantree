require 'highline/import'
require 'colorize'

module Gantree
  class Delete < Base

    def initialize stack_name,options
      check_credentials
      set_aws_keys
      @stack_name = stack_name
      @options = options
    end

    def run input=""
      input = "y" if  @options[:force]
      input ||= ask "Are you sure? (y|n)"
      if input == "y" || @options[:force]
        puts "Deleting stack from aws"
        return if @options[:dry_run]
        puts "Deleted".green if cfm.stacks[@stack_name].delete
      else
        puts "canceling...".yellow
      end
    end
  end
end

