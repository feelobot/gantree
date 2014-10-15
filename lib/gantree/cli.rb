require 'thor'
require 'aws-sdk-v1'
require 'gantree/cli/help'

module Gantree
  class CLI < Thor

    desc "deploy APP", "deploy specified APP"
    option :branch, :desc => 'branch to deploy'
    method_option :tag, :aliases => "-t", :desc => "set docker tag to deploy"
    method_option :env, :aliases => "-e", :desc => "elastic beanstalk environment"
    method_option :ext, :aliases => "-x", :desc => "ebextensions folder/repo"
    option :dry_run, :aliases => "-d", :desc => "do not actually deploy the app"
    def deploy app
      Gantree::Deploy.new(app, options.merge(gantreecfg)).run
    end

    desc "init IMAGE", "create a dockerrun for your IMAGE"
    method_option :user, :aliases => "-u", :desc => "user credentials for private repo"
    method_option :port, :aliases => "-p", :desc => "port of running application"
    def init image
      Gantree::Init.new(image,options).run
    end

    desc "create APP", "create or update a cfn stack"
    method_option :env, :aliases => "-e", :desc => "(optional) environment name"
    method_option :instance_size, :aliases => "-i", :desc => "(optional) set instance size"
    method_option :rds, :aliases => "-r", :desc => "(optional) set database type [pg,mysql]"
    option :dry_run, :aliases => "-d", :desc => "do not actually create the stack"
    option :docker_version, :desc => "set the version of docker to use as solution stack"
    option :db_instance_size, :desc => "set the db instance size"
    def create app
      Gantree::Stack.new(app, options.merge(gantreecfg)).create
    end

    protected
    def gantreecfg
      if File.exist?(".gantreecfg")
        defaults = JSON.parse(IO.read(".gantreecfg"))
      else
        {}
      end
    end
  end
end
