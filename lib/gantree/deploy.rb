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
      print_options
    end

    def run
      check_eb_bucket
      if application?
        DeployApplication.new(@name,@options).run
      elsif environment?
        puts "Found Environment: #{name}".green
        deploy([name])
      else
        error_msg "You leave me with nothing to deploy".red
      end
    end

    def environment_found?
      @environments.length >=1 ? true : false
    end

    def deploy_to_one
      env = @environments.first[:environment_name]
      puts "Found Environment: #{env}".green
      deploy([env])
    end

    def application?
      results = eb.describe_applications({ application_names: ["#{@name}"]})
      results[:applications].length == 1 ? true : false
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
      check_dir_name(envs) unless @options[:force]
      return if @options[:dry_run]
      @packaged_version = DeployVersion.new(@options).run
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
      check_version_bucket
      puts "uploading #{@packaged_version} to #{@app}-versions"
      s3.buckets["#{@options[:eb_bucket]}"].objects["#{@app}-versions"].write(:file => @packaged_version)
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
        rescue AWS::ElasticBeanstalk::Errors::InvalidParameterValue => e
          puts "Error: Something went wrong during the deploy to #{env}".red
          puts "#{e.message}"
        end
      end
    end

    def check_dir_name envs
      dir_name = File.basename(Dir.getwd)
      msg = "WARN: You are deploying from a repo that doesn't match #{@app}"
      puts msg.yellow if envs.any? { |env| env.include?(dir_name) } == false
    end

    def check_eb_bucket
      if @options[:eb_bucket]
        bucket = @options[:eb_bucket]
      else
        bucket = generate_eb_bucket
      end
      s3.buckets.create(bucket) unless s3.buckets[bucket].exists?
    end
    def generate_eb_bucket 
      unique_hash = Digest::SHA1.hexdigest ENV['AWS_ACCESS_KEY_ID']
      "eb_bucket_#{unique_hash}"
    end
  end
end

