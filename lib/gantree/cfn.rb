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
    end

    def check_credentials
      raise "Please set your AWS Environment Variables" if ENV['AWS_SECRET_ACCESS_KEY'] == nil
      raise "Please set your AWS Environment Variables" if ENV['AWS_ACCESS_KEY_ID'] == nil
    end

    def create
      @options[:rds_enabled] = rds_enabled? unless 
      create_cfn_if_needed
      generate("master", MasterTemplate.new(@options).create)
      generate("beanstalk", BeanstalkTemplate.new(@options).create)
      generate("resources", ResourcesTemplate.new(@options).create)
      upload_templates unless @options[:dry_run]
      create_aws_cfn_stack unless @options[:dry_run]
    end

    def update
      puts "Updating from local cfn repo"
      upload_templates unless @options[:dry_run]
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
    end

    def upload_templates
      check_for_template_bucket
      templates = ['master','resources','beanstalk']
      templates.each do |template|
        filename = "cfn/#{@env}-#{template}.cfn.json"
        key = File.basename(filename)
        @s3.buckets["#{@options[:cfn_bucket]}/#{@env}"].objects[key].write(:file => filename)
      end
      puts "templates uploaded"
    end

    def check_template_bucket
      bucket_name = "#{@options[:cfn_bucket]}/#{@env}"
      if @s3.buckets[bucket_name].exists?
        puts "uploading cfn templates to #{@options[:cfn_bucket]}/#{@env}"
      else
        puts "creating bucket #{@options[:cfn_bucket]}/#{@env} to upload templates"
        @s3.buckets.create(bucket_name) 
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
