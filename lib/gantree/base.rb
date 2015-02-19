require "colorize"
module Gantree
  class Base
    def check_credentials
      raise "Please set your AWS Environment Variables" unless ENV['AWS_SECRET_ACCESS_KEY']
      raise "Please set your AWS Environment Variables" unless ENV['AWS_ACCESS_KEY_ID']
    end

    def print_options
      @options.each do |param, value|
        puts "#{param}: #{value}"
      end
    end

    def set_aws_keys
      AWS.config(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
      )
    end

    def s3
      @s3 ||= AWS::S3.new
    end

    def eb
      @eb ||= AWS::ElasticBeanstalk::Client.new
    end

    def cfm
      @cfm ||= AWS::CloudFormation.new
    end


    def tag
      origin = `git config --get remote.origin.url`.match("com(.*)\/")[1].gsub(":","").gsub("/","").strip
      branch = `git rev-parse --abbrev-ref HEAD`.gsub("/", "_").strip
      hash = `git rev-parse --verify --short #{branch}`.strip
      "#{origin}-#{branch}-#{hash}"
    end

    def create_default_env
      tags = @options[:stack_name].split("-")
      if tags.length == 3
        [tags[1],tags[0],"app",tags[2]].join('-')
      else
        raise "Please Set Envinronment Name with -e"
      end
    end

    def env_type
      if @options[:env].include?("prod")
        "prod"
      elsif @options[:env].include?("stag")
        "stag"
      else
        ""
      end
    end

    def get_latest_docker_solution
      result = eb.list_available_solution_stacks
      solutions = result[:solution_stacks]
      docker_solutions = solutions.select { |s|  s.include? "running Docker"}
      docker_solutions.first
    end


    def escape_characters_in_string(string)
      pattern = /(\'|\"|\.|\*|\/|\-|\\)/
      string.gsub(pattern){|match|"\\"  + match} # <-- Trying to take the currently found match and add a \ before it I have no idea how to do that).
    end

    def upload_templates
      check_template_bucket
      @templates.each do |template|
        filename = "cfn/#{@options[:stack_name]}-#{template}.cfn.json"
        key = File.basename(filename)
        s3.buckets["#{@options[:cfn_bucket]}/#{@options[:stack_name]}"].objects[key].write(:file => filename)
      end
      puts "templates uploaded"
    end

    def check_template_bucket
      puts "DEBUG: #{@options[:cfn_bucket]}"
      raise "Set Bucket to Upload Templates with --cfn-bucket" unless @options[:cfn_bucket]
      bucket_name = "#{@options[:cfn_bucket]}/#{@options[:stack_name]}"
      if s3.buckets[bucket_name].exists?
        puts "uploading cfn templates to #{@options[:cfn_bucket]}/#{@options[:stack_name]}"
      else
        puts "creating bucket #{@options[:cfn_bucket]}/#{@options[:stack_name]} to upload templates"
        s3.buckets.create(bucket_name) 
      end
    end

    def error_msg msg
      puts msg.red
      exit 1
    end
  end
end

