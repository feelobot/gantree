require 'json'
require 'archive/zip'
require 'colorize'
require_relative 'notification'

module Gantree
  class DeployApplication < Deploy
    attr_accessor :options

    def initialize name, options
      @options = options
      @name = name
      puts "Found Application: #{@name}".green
      @environments = eb.describe_environments({ :application_name => @name })[:environments]
    end

    def run
      if multiple_environments?
        deploy_to_all
      elsif environment_found?
        deploy_to_one
      else
        error_msg "ERROR: There are no environments in this application"
      end
    end

    def multiple_environments?
      @environments.length > 1 ? true : false
    end

    def environment_found?
      @environments.length >=1 ? true : false
    end

    def deploy_to_all
      puts "WARN: Deploying to All Environments in the Application: #{@name}".yellow
      sleep 3
      envs = []
      @environments.each do |env|
        envs << env[:environment_name]
      end
      puts "envs: #{envs}"
      deploy(envs)
    end
  end
end

