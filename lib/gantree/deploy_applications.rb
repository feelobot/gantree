require 'json'
require 'archive/zip'
require 'colorize'
require_relative 'notification'

module Gantree
  class DeployApplication < Deploy
    attr_reader :name

    def initialize name, options
      puts "Found Application: #{@name}".green
      @environments = eb.describe_environments({ :application_name => @app })[:environments]
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

    def create_version_files
      time_stamp = Time.now.to_i
      branch = `git rev-parse --abbrev-ref HEAD`
      puts "branch: #{branch}"
      hash = `git rev-parse --verify --short #{branch}`.strip
      puts "hash #{hash}"
      version = "#{@app}-#{hash}-#{time_stamp}"
      puts "version: #{version}"
      #auto_detect_app_role if @options[:autodetect_app_role] == true
      set_image_path if @options[:image_path]
      set_tag_to_deploy if @options[:tag]
      unless ext?
        new_dockerrun = "#{version}-Dockerrun.aws.json"
        FileUtils.cp("Dockerrun.aws.json", new_dockerrun)
        new_dockerrun
      else
        zip = "#{version}.zip"
        clone_repo if repo?
        Archive::Zip.archive(zip, ['.ebextensions/', @dockerrun_file])
        zip
      end
    end

    def set_tag_to_deploy
      docker = JSON.parse(IO.read(@dockerrun_file))
      image = docker["Image"]["Name"]
      image.gsub!(/:(.*)$/, ":#{@options[:tag]}")
      IO.write(@dockerrun_file, JSON.pretty_generate(docker))
    end

    def set_image_path
      docker = JSON.parse(IO.read(@dockerrun_file))
      image = docker["Image"]["Name"]
      image.gsub!(/(.*):/, "#{@options[:image_path]}:")
      IO.write(@dockerrun_file, JSON.pretty_generate(docker))
      image
    end

    def autodetect_app_role env
      enabled = @options[:autodetect_app_role]
      if enabled == true || enabled == "true"
        role = env.split('-')[2]
        puts "Deploying app as a #{role}"
        [{:option_name => "ROLE", :value => role, :namespace => "aws:elasticbeanstalk:application:environment" }]
      else 
        []
      end
    end
  end
end

