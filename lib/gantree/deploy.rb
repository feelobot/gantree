require 'json'
require 'archive/zip'
require 'colorize'
require_relative 'notification'

module Gantree
  class Deploy < Base
    attr_reader :name

    def initialize name, options
      check_credentials
      set_aws_keys
      @name = name
      @options = options
      @ext = @options[:ext]
      @dockerrun_file = "Dockerrun.aws.json"
    end

    def run
      if application?
        puts "Found Application: #{@name}".green
        environments = eb.describe_environments({ :application_name => @app })[:environments]
        if environments.length > 1
          puts "WARN: Deploying to All Environments in the Application: #{@name}".yellow
          sleep 3
          envs = []
          environments.each do |env|
            envs << env[:environment_name]
          end
          puts "envs: #{envs}"
          deploy(envs)
        elsif environments.length == 1
          env = environments.first[:environment_name]
          puts "Found Environment: #{env}".green
          deploy([env])
        else
          puts "ERROR: There are no environments in this application".red
          exit 1
        end
      elsif environment?
        puts "Found Environment: #{name}".green
        deploy([name])
      else
        puts "You leave me with nothing to deploy".red
        exit 1
      end
    end

    def application?
      results = eb.describe_applications({ application_names: ["#{@name}"]})
      if results[:applications].length > 1
        raise "There are more than 1 matching application names"
      elsif results[:applications].length == 0
        return false
      else 
        @app = results[:applications][0][:application_name]
        return true
      end
    end

    def environment?
      results = eb.describe_environments({ environment_names: ["#{@name}"]})[:environments]
      if results.length == 0
        puts "ERROR: Environment '#{name}' not found"
        exit 1
      else
        @app = results[0][:application_name]
        return true
      end
    end

    def deploy(envs)
      print_options
      check_dir_name(envs) unless @options[:force]
      return if @options[:dry_run]
      @packaged_version = create_version_files
      upload_to_s3 
      clean_up 
      create_eb_version
      update_application(envs)
      if @options[:slack]
        msg = "#{ENV['USER']} is deploying #{@packaged_version} to #{@app} "
        msg += "Tag: #{@options[:tag]}" if @options[:tag]
        Notification.new(@options[:slack]).say(msg) unless @options[:silent]
      end
    end

    def upload_to_s3
      key = File.basename(@packaged_version)
      check_version_bucket
      puts "uploading #{@packaged_version} to #{@app}-versions"
      s3.buckets["#{@app}-versions"].objects[key].write(:file => @packaged_version)
    end

    def create_eb_version
    begin
      eb.create_application_version({
        :application_name => @app,
        :version_label => @packaged_version,
        :source_bundle => {
          :s3_bucket => "#{@app}-versions",
          :s3_key => @packaged_version
        }
      })
      rescue AWS::ElasticBeanstalk::Errors::InvalidParameterValue => e
        puts "No Application named #{@app} found #{e}"
      end
    end

    def update_application(envs)
      envs.each do |env|
        begin
          eb.update_environment({
            :environment_name => env,
            :version_label => @packaged_version,
            :option_settings => autodetect_app_role(env)
          })
          puts "Deployed #{@packaged_version} to #{env} on #{@app}".green
        rescue AWS::ElasticBeanstalk::Errors::InvalidParameterValue
          puts "Error: Something went wrong during the deploy to #{env}".red
        end
      end
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

    def ext?
      if @ext
        true
      else
        false
      end
    end

    def repo?
      if @ext.include? "github"
        puts "Cloning: #{@ext}..."
        true
      else
        false
      end
    end

    def local?
      File.directory?(@ext)
    end

    def get_ext_repo
      if ext_branch?
        repo = @ext.sub(":#{get_ext_branch}", '')
      else
        @ext
      end
    end

    def ext_branch?
      if @ext.count(":") == 2
        true
      else
        false
      end
    end

    def get_ext_branch
      branch = @ext.match(/:.*(:.*)$/)[1]
      branch.tr(':','')
    end

    def clone_repo
      if ext_branch?
        `git clone -b #{get_ext_branch} #{get_ext_repo}`
      else
        `git clone #{get_ext_repo}`
      end
    end

    def check_version_bucket
      name = "#{@app}-versions"
      bucket = s3.buckets[name] # makes no request
      s3.buckets.create(name) unless bucket.exists?
    end

    def clean_up
      FileUtils.rm_rf(@packaged_version)
      `git checkout Dockerrun.aws.json` # reverts back to original Dockerrun.aws.json
      `rm -rf .ebextensions/` if ext?
    end

    def check_dir_name envs
      dir_name = File.basename(Dir.getwd)
      msg = "WARN: You are deploying from a repo that doesn't match #{@app}"
      puts msg.yellow if envs.any? { |env| env.include?(dir_name) } == false
    end
  end
end

