require 'cloudformation-ruby-dsl'
require_relative 'cfn/master'
require_relative 'cfn/beanstalk'
require_relative 'cfn/resources'

module Gantree
  class Stack
    def initialize stack_name,options
      check_credentials
      AWS.config(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCES_KEY'])
      @s3 = AWS::S3.new
      @cfm = AWS::CloudFormation.new
      @size = options[:instance_size]
      @size ||= "t1.micro"
      @requirements = "#!/usr/bin/env ruby
        require 'bundler/setup'
        require 'cloudformation-ruby-dsl/cfntemplate'
        require 'cloudformation-ruby-dsl/spotprice'
        require 'cloudformation-ruby-dsl/table'"
      @env = options[:env] || stack_name.match(/^[a-zA-Z]*\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[1] + "-" + stack_name.match(/^([a-zA-Z]*)\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[1] + '-' + stack_name.match(/^([a-zA-Z]*)\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[3]
      additional_options = {
        instance_size: @size,
        stack_name: stack_name,
        requirements: @requirements,
        cfn_bucket: "br-templates",
        env: @env,
        stag_domain: "sbleacherreport.com",
        prod_domain: "bleacherreport.com",
        env_type: env_type,
      }
      @options = options.merge(additional_options)
      @options[:rds_enabled] = rds_enabled?
    end

    def check_credentials
      raise "Please set your AWS Environment Variables" if ENV['AWS_SECRET_ACCESS_KEY'] == nil
      raise "Please set your AWS Environment Variables" if ENV['AWS_ACCESS_KEY_ID'] == nil
    end

    def create
      create_cfn_if_needed
      generate("master", MasterTemplate.new(@options).create)
      generate("beanstalk", BeanstalkTemplate.new(@options).create)
      generate("resources", ResourcesTemplate.new(@options).create)
      puts "All templates created"
      create_aws_cfn_stack if @options[:dry_run].nil?
    end

    def create_cfn_if_needed
      Dir.mkdir 'cfn' unless File.directory?("cfn")
    end

    def generate(template_name, template)
      IO.write("cfn/#{template_name}.rb", template)
      json = `ruby cfn/#{template_name}.rb expand`
      Dir.mkdir 'cfn' rescue Errno::ENOENT
      template_file_name = "#{@env}-#{template_name}.cfn.json"
      IO.write("cfn/#{template_file_name}", json)
      puts "Created #{template_file_name} in the cfn directory"
      FileUtils.rm("cfn/#{template_name}.rb")
      upload_template_to_s3("cfn/#{template_file_name}")
    end

    def upload_template_to_s3(filename)
      begin
        puts "uploading cfn template to #{@options[:cfn_bucket]}/#{@env}"
        key = File.basename(filename)
        @s3.buckets["#{@options[:cfn_bucket]}/#{@env}"].objects[key].write(:file => filename)
      rescue AWS::S3::Errors::NoSuchBucket
        puts "bucket didn't exist...creating"
        bucket = @s3.buckets.create("#{@options[:cfn_bucket]}/#{@env}")
        retry
      rescue AWS::S3::Errors::AccessDenied
        puts "Your key is not configured for s3 access, please let your operations team know"
      end
    end

    def create_aws_cfn_stack
      puts "Creating stack on aws..."
      template = AWS::S3.new.buckets["#{@options[:cfn_bucket]}/#{@env}"].objects["#{@env}-master.cfn.json"]
      stack = @cfm.stacks.create(@options[:stack_name], template,{ :disable_rollback => true })
    end

    def rds_enabled?
      if @options[:rds] == nil
        puts "RDS is not enabled, no DB created"
        false
      elsif @options[:rds] == "pg" || @rds == "mysql"
        puts "RDS is enabled, creating DB"
        true
      else
        raise "The --rds option you passed is not supported please use 'pg' or 'mysql'"
      end
    end

    def env_type
      if @env.include?("prod")
        "prod"
      elsif @env.include?("stag")
        "stag"
      else
        ""
      end
    end
  end
end
