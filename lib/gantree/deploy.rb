require 'json'
require 'archive/zip'
require_relative 'notification'

module Gantree
  class Deploy < Base
    attr_reader :app, :env

    def initialize app, options
      check_credentials
      set_aws_keys

      @options = options
      @ext = @options[:ext]
      @app = @options[:env] || default_name(app)
      @env = app
      @dockerrun_file = "Dockerrun.aws.json"
    end

    def run
      puts "Deploying #{@env} on #{@app}"
      print_options
      return if @options[:dry_run]
      @packaged_version = create_version_files
      upload_to_s3 if @options[:dry_run].nil?
      clean_up
      create_eb_version if @options[:dry_run].nil?
      update_application if @options[:dry_run].nil?
      if @options[:slack]
        msg = "#{ENV['USER']} is deploying #{@packaged_version} to #{@app}"
        Notification.new(@options[:slack]).say(msg) unless @options[:silent]
      end
    end

    private
    def eb
      @eb ||= AWS::ElasticBeanstalk::Client.new
    end

    def upload_to_s3
      key = File.basename(@packaged_version)
      check_version_bucket
      puts "uploading #{@packaged_version} to #{@app}-versions"
      s3.buckets[bucket_name].objects[key].write(:file => @packaged_version)
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

    def update_application
      begin
        eb.update_environment({
          :environment_name => @env,
          :version_label => @packaged_version,
          :option_settings => autodetect_app_role
        })
      rescue AWS::ElasticBeanstalk::Errors::InvalidParameterValue
        puts "#{@env} doesn't exist"
      end
    end

    def create_version_files
      time_stamp = Time.now.to_i
      branch = `git rev-parse --abbrev-ref HEAD`
      puts "branch: #{branch}"
      hash = `git rev-parse --verify --short #{branch}`.strip
      puts "hash #{hash}"
      version = "#{@env}-#{hash}-#{time_stamp}"
      puts "version: #{version}"
      #auto_detect_app_role if @options[:autodetect_app_role] == true
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

    def autodetect_app_role
      enabled = @options[:autodetect_app_role]
      if enabled == true || enabled == "true"
        role = @env.split('-')[2]
        puts "Deploying app as a #{role}"
        #role_cmd = IO.read("roles/#{role}").gsub("\n",'')
        #docker = JSON.parse(IO.read(@dockerrun_file))
        #docker["Cmd"] = role_cmd
        #IO.write(@dockerrun_file,JSON.pretty_generate(docker))
        #puts "Setting role cmd to '#{role_cmd}'"
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
      bucket = s3.buckets[bucket_name] # makes no request
      s3.buckets.create(name) unless bucket.exists?
    end

    def clean_up
      FileUtils.rm_rf(@packaged_version)
      `git checkout Dockerrun.aws.json` # reverts back to original Dockerrun.aws.json
      `rm -rf .ebextensions/` if ext?
    end
    
    def bucket_name
      [user_from_dockerrun_file, @app, "versions"].compact.join("-")
    end

    def user_from_dockerrun_file
      docker = JSON.parse(IO.read(@dockerrun_file))
      return nil unless auth_hash = docker["Authentication"]
      return nil unless key = auth_hash["Key"]
      key.split(".").first
    end
  end
end

