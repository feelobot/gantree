require "pry"
require 'thor'
require 'aws-sdk-v1'
require 'gantree/cli/help'

module Gantree
  class CLI < Thor

    class_option :dry_run, :aliases => "-d", :desc => "dry run mode", :default => false, :type => :boolean

    desc "deploy APP", "deploy specified APP"
    long_desc Help.deploy
    option :tag, :aliases => "-t", :desc => "set docker tag to deploy", :default => Gantree::Base.new.tag
    option :ext, :aliases => "-x", :desc => "ebextensions folder/repo"
    option :ext_role, :desc => "role based extension repo (bleacher specific)"
    option :silent, :aliases => "-s", :desc => "mute notifications"
    option :image_path, :aliases => "-i", :desc => "docker hub image path ex. (bleacher/cms | quay.io/bleacherreport/cms)"
    option :autodetect_app_role, :desc => "use naming convention to determin role (true|false)", :type => :boolean, :default => true
    option :eb_bucket, :desc => "bucket to store elastic beanstalk versions"
    option :auth, :desc => "dockerhub authentation, example: bucket/key"
    option :release_notes_staging, :type => :boolean, :default => false, :desc => "force release notes generation for staging deploys"
    def deploy name
      opts = Gantree::Config.merge_defaults(options)
      opts = Gantree::Base.check_for_updates(opts)
      Gantree::Deploy.new(name,opts).run 
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
    option :cfn_bucket, :desc => "s3 bucket to store cfn templates"
    option :domain, :desc => "route53 domain"
    option :env, :aliases => "-e", :desc => "(optional) environment name"
    option :instance_size, :aliases => "-i", :desc => "(optional) set instance size", :default => "m3.medium"
    option :rds, :aliases => "-r", :desc => "(optional) set database type [pg,mysql]"
    option :solution, :aliases => "-s", :desc => "change solution stack"
    option :dupe, :alias => "-d", :desc => "copy an existing template into a new template"
    option :local, :alias => "-l", :desc => "use a local cfn nested template"
    def create app
      Gantree::Create.new(app, Gantree::Config.merge_defaults(options)).run
    end

    desc "update APP", "update a cfn stack"
    long_desc Help.update
    option :cfn_bucket, :desc => "s3 bucket to store cfn templates"
    option :role, :aliases => "-r", :desc => "add an app role (worker|listner|scheduler)"
    option :solution, :aliases => "-s", :desc => "change solution stack"
    def update app
      Gantree::Update.new(app, Gantree::Config.merge_defaults(options)).run
    end

    desc "delete APP", "delete a cfn stack"
    option :force, :desc => "do not prompt", :default => false
    def delete app
      Gantree::Delete.new(app, Gantree::Config.merge_defaults(options)).run
    end

    desc "restart APP", "restart an eb app"
    def restart app
      Gantree::App.new(app, Gantree::Config.merge_defaults(options)).restart
    end

    desc "build", "build and tag a docker application"
    long_desc Help.build
    option :image_path, :aliases => "-i", :desc => "docker hub image path ex. (bleacher/cms | quay.io/bleacherreport/cms)"
    option :tag, :aliases => "-t", :desc => "set docker tag to build"
    def build
      docker = Gantree::Docker.new(Gantree::Config.merge_defaults(options))
      docker.build
    end

    desc "push", "build and tag a docker application"
    long_desc Help.push
    option :hub, :aliases => "-h", :desc => "hub (docker|quay)"
    option :image_path, :aliases => "-i", :desc => "docker hub image path ex. (bleacher/cms | quay.io/bleacherreport/cms)"
    option :tag, :aliases => "-t", :desc => "set docker tag to push"
    def push
      Gantree::Docker.new(Gantree::Config.merge_defaults(options)).push
    end

    desc "tag", "tag a docker application"
    def tag
      puts Gantree::Base::new.tag
    end

    desc "ship", "build, push and deploy docker container to elastic beanstalk"
    long_desc Help.ship
    option :tag, :aliases => "-t", :desc => "set docker tag to deploy", :default => Gantree::Base.new.tag
    option :ext, :aliases => "-x", :desc => "ebextensions folder/repo"
    option :silent, :aliases => "-s", :desc => "mute notifications"
    option :autodetect_app_role, :desc => "use naming convention to determin role (true|flase)", :type => :boolean
    option :image_path, :aliases => "-i", :desc => "hub image path ex. (bleacher/cms | quay.io/bleacherreport/cms)"
    option :hush, :desc => "quite puts messages", :default => true
    option :eb_bucket, :desc => "bucket to store elastic beanstalk versions"
    option :auth, :desc => "dockerhub authentation, example: bucket/key"
    option :release_notes_staging, :type => :boolean, :default => false, :desc => "force release notes generation for staging deploys"
    def ship server
      opts = Gantree::Config.merge_defaults(options)
      opts = Gantree::Base.check_for_updates(opts)
      docker = Gantree::Docker.new(opts)
      docker.pull
      docker.build
      docker.push
      Gantree::Deploy.new(server,opts).run
    end

    map "-v" => :version
    desc "version", "gantree version"
    def version
      puts VERSION
    end

  end
end

