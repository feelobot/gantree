require 'thor'
require 'aws-sdk'
require 'gantree/cli/help'

module Gantree
  class CLI < Thor

    desc "deploy APP", "deploy specified APP"
    option :branch, :desc => 'branch to deploy'
    method_option :tag, :aliases => "-t", :desc => "set docker tag to deploy"
    method_option :env, :aliases => "-e", :desc => "elastic beanstalk environment"
    def deploy app
      Gantree::Deploy.new(app, options).run
    end

    desc "init IMAGE", "create a dockerrun for your IMAGE"
    method_option :user, :aliases => "-u", :desc => "user credentials for private repo"
    method_option :port, :aliases => "-p", :desc => "port of running application"
    def init image
      Gantree::Init.new(image,options).run
    end

    desc "create APP", "create or update a cfn stack"
    method_option :env, :aliases => "-e", :desc => "(optional) environment name"
    method_option :instance_size, :alias => "-i", :desc => "(optional) set instance size"
    method_option :rds, :alias => "-d", :desc => "(optional) set database type [pg,mysql]"
    def create app
      Gantree::Stack.new(app, options).create
    end
  end
end
