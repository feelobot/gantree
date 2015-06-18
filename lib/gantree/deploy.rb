require 'json'
require 'archive/zip'
require 'colorize'
require 'librato/metrics'
require_relative 'release_notes'
require_relative 'wiki'
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
      @envs = envs
      check_dir_name(envs) unless @options[:force]
      return if @options[:dry_run]
      version = DeployVersion.new(@options, envs[0])
      @packaged_version = version.run
      puts @packaged_version
      upload_to_s3 
      create_eb_version
      update_application(envs)
      if @options[:slack]
        msg = "#{ENV['USER']} is deploying #{@packaged_version} to #{@app} "
        msg += "Tag: #{@options[:tag]}" if @options[:tag]
        Notification.new(@options[:slack]).say(msg) unless @options[:silent]
      end
      if @options[:librato]
        puts "Found Librato Key"
        Librato::Metrics.authenticate @options[:librato]["email"], @options[:librato]["token"]
        Librato::Metrics.annotate :deploys, "deploys",:source => "#{@app}", :start_time => Time.now.to_i
        puts "Librato metric submitted" 
      end
      if @options[:release_notes_wiki] == "enabled" && prod_deploy? && @app.include?("-app-")
        ReleaseNotes.new(@options[:release_notes_wiki], @app, new_hash).create
        `git tag #{tag}`
        `git push --tags`
      end
      version.clean_up
    end

    def upload_to_s3
      puts "uploading #{@packaged_version} to #{set_bucket}"
      s3.buckets["#{set_bucket}"].objects["#{@app}-#{@packaged_version}"].write(:file => @packaged_version)
    end

    def create_eb_version
      begin
        eb.create_application_version({
          :application_name => "#{@app}",
          :version_label => "#{@packaged_version}",
          :source_bundle => {
            :s3_bucket => "#{set_bucket}",
            :s3_key => "#{@app}-#{@packaged_version}"
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
            :version_label => @packaged_version
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
      bucket = set_bucket
      puts "S3 Bucket: #{bucket}".light_blue
      s3.buckets.create(bucket) unless s3.buckets[bucket].exists?
    end

    def set_bucket
      if @options[:eb_bucket]
        bucket = @options[:eb_bucket]
      else
        bucket = generate_eb_bucket
      end
    end
    
    def generate_eb_bucket 
      unique_hash = Digest::SHA1.hexdigest ENV['AWS_ACCESS_KEY_ID']
      "eb-bucket-#{unique_hash}"
    end

    def prod_deploy?
      @envs.first.split("-").first == "prod" 
    end 
    def new_hash
      @packaged_version.split("-")[2]
    end
  end
end

