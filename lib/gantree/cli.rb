require "pry"
require 'thor'
require 'aws-sdk-v1'
require 'gantree/cli/help'

module Gantree
  class CLI < Thor

    class_option :dry_run, :aliases => "-d", :desc => "dry run mode"

    desc "deploy APP", "deploy specified APP"
    long_desc Help.deploy
    option :branch, :desc => 'branch to deploy'
    method_option :tag, :aliases => "-t", :desc => "set docker tag to deploy"
    method_option :ext, :aliases => "-x", :desc => "ebextensions folder/repo"
    option :silent, :aliases => "-s", :desc => "mute notifications"
    option :image_path, :aliases => "-i", :desc => "docker hub image path ex. (bleacher/cms | quay.io/bleacherreport/cms)"
    option :autodetect_app_role, :desc => "use naming convention to determin role"
    def deploy name
      Gantree::Deploy.new(name, merge_defaults(options)).run
    end

    desc "init IMAGE", "create a dockerrun for your IMAGE"
    long_desc Help.init
    method_option :user   , :aliases => "-u", :desc => "user credentials for private dockerhub repo"
    method_option :port   , :aliases => "-p", :desc => "port of running application"
    method_option :bucket , :aliases => "-b", :desc => "set bucket name, default is '<user>-docker-cfgs'"
    def init image
      Gantree::Init.new(image, options).run
    end

    desc "create APP", "create a cfn stack"
    long_desc Help.create
    method_option :env, :aliases => "-e", :desc => "(optional) environment name"
    method_option :instance_size, :aliases => "-i", :desc => "(optional) set instance size", :default => "m3.medium"
    method_option :rds, :aliases => "-r", :desc => "(optional) set database type [pg,mysql]"
    option :docker_version, :desc => "set the version of docker to use as solution stack"
    option :dupe, :desc => "copy an existing template into a new template"
    option :local, :desc => "use a local cfn nested template"
    def create app
      Gantree::Stack.new(app, merge_defaults(options)).create
    end

    desc "update APP", "update a cfn stack"
    long_desc Help.update
    option :role, :aliases => "-r", :desc => "add an app role (worker|listner|scheduler)"
    def update app
      Gantree::Stack.new(app, merge_defaults(options)).update
    end

    desc "delete APP", "delete a cfn stack"
    option :force, :desc => "do not prompt"
    def delete app
      Gantree::Stack.new(app, merge_defaults(options)).delete
    end

    desc "restart APP", "restart an eb app"
    def restart app
      Gantree::App.new(app, merge_defaults(options)).restart
    end

    desc "build", "build and tag a docker application"
    long_desc Help.build
    option :image_path, :aliases => "-i", :desc => "docker hub image path ex. (bleacher/cms | quay.io/bleacherreport/cms)"
    option :tag, :aliases => "-t", :desc => "set docker tag to build"
    def build
      Gantree::Docker.new(merge_defaults(options)).build
    end

    desc "push", "build and tag a docker application"
    long_desc Help.push
    option :hub, :aliases => "-h", :desc => "hub (docker|quay)"
    option :image_path, :aliases => "-i", :desc => "docker hub image path ex. (bleacher/cms | quay.io/bleacherreport/cms)"
    option :tag, :aliases => "-t", :desc => "set docker tag to push"
    def push
      Gantree::Docker.new(merge_defaults(options)).push
    end

    desc "tag", "tag a docker application"
    def tag
      puts Gantree::Docker.new(merge_defaults(options)).tag
    end

    desc "ship", "build, push and deploy docker container to elastic beanstalk"
    long_desc Help.ship
    option :branch, :desc => 'branch to deploy'
    option :tag, :aliases => "-t", :desc => "set docker tag to deploy", :default => Gantree::Base.new.tag
    option :ext, :aliases => "-x", :desc => "ebextensions folder/repo"
    option :silent, :aliases => "-s", :desc => "mute notifications"
    option :autodetect_app_role, :desc => "use naming convention to determin role"
    option :image_path, :aliases => "-i", :desc => "hub image path ex. (bleacher/cms | quay.io/bleacherreport/cms)"
    option :hush, :desc => "quite puts messages", :default => true
    def ship server
      docker = Gantree::Docker.new(merge_defaults(options))
      docker.build
      docker.push
      Gantree::Deploy.new(server, merge_defaults(options)).run
    end

    map "-v" => :version
    desc "version", "gantree version"
    def version
      puts VERSION
    end

    protected

    def merge_defaults(options={})
       if File.exist?(".gantreecfg")
         defaults = JSON.parse(File.open(".gantreecfg").read)
         hash = defaults.merge(options)
         Hash[hash.map{ |k, v| [k.to_sym, v] }]
       else
         Hash[options.map{ |k, v| [k.to_sym, v] }]
       end
     end
  end
end

