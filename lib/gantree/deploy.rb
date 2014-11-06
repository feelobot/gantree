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
      @app = @options[:env] || default_app_name(app)
      @env = app
    end

    def run
      puts "Deploying #{@app}"
      @packaged_version = create_version_files
      upload_to_s3 if @options[:dry_run].nil?
      clean_up
      create_eb_version if @options[:dry_run].nil?
      update_application if @options[:dry_run].nil?
      if @options[:slack]
        Notification.new(@options[:slack]).say("hello") unless @options[:silent]
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

    def update_application
      begin
        eb.update_environment({
          :environment_name => @env,
          :version_label => @packaged_version
        })
      rescue AWS::ElasticBeanstalk::Errors::InvalidParameterValue
        puts "#{@env} doesn't exist"
      end
    end

    def create_version_files
      unique_hash = (0...8).map { (65 + rand(26)).chr }.join
      branch = `git rev-parse --abbrev-ref HEAD`
      puts "branch: #{branch}"
      hash = `git rev-parse --verify --short #{branch}`.strip
      puts "hash #{hash}"
      version = "#{@env}-#{hash}-#{unique_hash}"
      puts "version: #{version}"
      dockerrun = "Dockerrun.aws.json"
      set_tag_to_deploy(dockerrun) if @options[:tag]
      unless ext?
        new_dockerrun = "#{version}-Dockerrun.aws.json"
        FileUtils.cp("Dockerrun.aws.json", new_dockerrun)
        new_dockerrun
      else
        zip = "#{version}.zip"
        clone_repo if repo?
        Archive::Zip.archive(zip, ['.ebextensions/', dockerrun])
        zip
      end
    end

    def set_tag_to_deploy file
      docker = JSON.parse(IO.read(file))
      docker["Image"]["Name"].gsub!(/:(.*)$/, ":#{@options[:tag]}")
      IO.write(file,JSON.pretty_generate(docker))
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
  end
end

