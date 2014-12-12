require "thor"
require "aws-sdk-v1"
require "gantree/cli/help"

module Gantree
  class CLI < Thor
    desc "deploy APP", "deploy specified APP"
    option :branch, desc: "branch to deploy"
    method_option :tag, aliases: "-t", desc: "set docker tag to deploy"
    method_option :ext, aliases: "-x", desc: "ebextensions folder/repo"
    option :dry_run, aliases: "-d", desc: "do not deploy app"
    option :silent, aliases: "-s", desc: "mute Slack notifications"
    option :image_path, aliases: "-i", desc: "docker hub image path (bleacher/cms | quay.io/bleacherreport/cms)"
    option :autodetect_app_role, desc: "use naming convention to determin role"
    def deploy(name)
      Gantree::Deploy.new(name, merge_defaults(options)).run
    end

    desc "init IMAGE", "create dockerrun for IMAGE"
    method_option :user, aliases: "-u", desc: "user credentials for private dockerhub repo"
    method_option :port, aliases: "-p", desc: "port of running application"
    method_option :bucket, aliases: "-b", desc: "set bucket name. default is '<user>-docker-cfgs'"
    option :dry_run, aliases: "-d", desc: "do not upload to s3 bucket"
    def init(image)
      Gantree::Init.new(image, options).run
    end

    desc "create APP", "create cfn stack"
    method_option :env, aliases: "-e", desc: "(optional) environment name"
    method_option :instance_size, aliases: "-i", desc: "(optional) set instance size", default: "m3.medium"
    method_option :rds, aliases: "-r", desc: "(optional) set database type [pg, mysql]"
    option :dry_run, aliases: "-d", desc: "do not create the stack"
    option :docker_version, desc: "set the version of docker to use as solution stack"
    option :dupe, desc: "copy existing template into a new template"
    option :local, desc: "use local cfn nested template"
    def create(app)
      Gantree::Stack.new(app, merge_defaults(options)).create
    end

    desc "update APP", "update cfn stack"
    option :dry_run, aliases: "-d", desc: "do not create stack"
    option :role, aliases: "-r", desc: "add an app role [worker, listener, scheduler]"
    def update(app)
      Gantree::Stack.new(app, merge_defaults(options)).update
    end

    desc "delete APP", "delete cfn stack"
    option :force, desc: "do not prompt"
    option :dry_run, aliases: "-d", desc: "do not create stack"
    def delete(app)
      Gantree::Stack.new(app, merge_defaults(options)).delete
    end

    desc "restart APP", "restart app"
    option :dry_run, aliases: "-d", desc: "do not restart"
    def restart(app)
      Gantree::App.new(app, merge_defaults(options)).restart
    end

    desc "build", "build and tag docker app"
    option :image_path, aliases: "-i", desc: "docker hub image path (bleacher/cms | quay.io/bleacherreport/cms)"
    option :tag, aliases: "-t", desc: "set docker tag to build"
    def build
      Gantree::Docker.new(merge_defaults(options)).build
    end

    desc "push", "build and tag docker app"
    option :image_path, aliases: "-i", desc: "docker hub image path (bleacher/cms | quay.io/bleacherreport/cms)"
    option :tag, aliases: "-t", desc: "set docker tag to push"
    def push
      Gantree::Docker.new(merge_defaults(options)).push
    end

    desc "tag", "tag docker app"
    def tag
      puts Gantree::Docker.new(merge_defaults(options)).tag
    end

    desc "ship", "tag docker app"
    option :branch, desc: "branch to deploy"
    option :tag, aliases: "-t", desc: "set docker tag to deploy", default: Gantree::Base.new.tag
    option :ext, aliases: "-x", desc: "ebextensions folder/repo"
    option :dry_run, aliases: "-d", desc: "do not deploy app"
    option :silent, aliases: "-s", desc: "mute Slack notifications"
    option :autodetect_app_role, desc: "use naming convention to determine role"
    option :image_path, aliases: "-i", desc: "hub image path (bleacher/cms | quay.io/bleacherreport/cms)"
    option :hush, desc: "quite puts messages", default: true
    def ship(server)
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

    def merge_defaults(options = {})
      if File.exist?(".gantreecfg")
        defaults = JSON.parse(File.open(".gantreecfg").read)
        hash = defaults.merge(options)
        Hash[hash.map { |k, v| [k.to_sym, v] }]
      else
        Hash[options.map { |k, v| [k.to_sym, v] }]
      end
    end
  end
end
