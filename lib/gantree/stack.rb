require 'cloudformation-ruby-dsl'
require 'highline/import'
require_relative 'cfn/master'
require_relative 'cfn/beanstalk'
require_relative 'cfn/resources'

module Gantree
  class Stack < Base
    attr_reader :env

    def initialize stack_name,options
      check_credentials
      set_aws_keys

      @cfm = AWS::CloudFormation.new
      @size = options[:instance_size]
      @size ||= "t2.medium"
      @requirements = "#!/usr/bin/env ruby
        require 'cloudformation-ruby-dsl/cfntemplate'
        require 'cloudformation-ruby-dsl/spotprice'
        require 'cloudformation-ruby-dsl/table'"
      @env = options[:env] || default_name(stack_name)
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

    def create
      @options[:rds_enabled] = rds_enabled? if @options[:rds] 
      print_options
      create_cfn_if_needed
      create_all_templates unless @options[:local]
      upload_templates unless @options[:dry_run]
      create_aws_cfn_stack unless @options[:dry_run]
    end

    def update
      puts "Updating stack from local cfn repo"
      unless @options[:dry_run] then
        upload_templates 
        @cfm.stacks[@options[:stack_name]].update(:template => stack_template) 
      end
    end

    def delete
      if @options[:force]
        input = "y"
      else
        input = ask "Are you sure? (y|n)"
      end
      if input == "y" || @options[:force]
        puts "Deleting stack from aws"
        @cfm.stacks[@options[:stack_name]].delete unless @options[:dry_run]
      else
        puts "canceling..."
      end
    end

    private
    def stack_template
      s3.buckets["#{@options[:cfn_bucket]}/#{env}"].objects["#{env}-master.cfn.json"]
    end

    def create_cfn_if_needed
      Dir.mkdir 'cfn' unless File.directory?("cfn")
    end

    def create_all_templates
      if @options[:dupe]
        puts "Duplicating cluster"
        orgin_stack_name = @options[:dupe]
        origin_env = @options[:dupe].match(/^[a-zA-Z]*\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[1] + "-" + env_from_dupe = @options[:dupe].match(/^([a-zA-Z]*)\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[1] + '-' + env_from_dupe = @options[:dupe].match(/^([a-zA-Z]*)\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[3]
        templates = ['master','resources','beanstalk']
        templates.each do |template|
          FileUtils.cp("cfn/#{origin_env}-#{template}.cfn.json", "cfn/#{env}-#{template}.cfn.json")
          file = IO.read("cfn/#{env}-#{template}.cfn.json")
          file.gsub!(/#{escape_characters_in_string(orgin_stack_name)}/, @options[:stack_name])
          file.gsub!(/#{escape_characters_in_string(origin_env)}/, @options[:env])
          IO.write("cfn/#{env}-#{template}.cfn.json",file)
        end
      else
        puts "Generating templates from gantree"
        generate("master", MasterTemplate.new(@options).create)
        generate("beanstalk", BeanstalkTemplate.new(@options).create)
        generate("resources", ResourcesTemplate.new(@options).create)
      end
    end

    def escape_characters_in_string(string)
      pattern = /(\'|\"|\.|\*|\/|\-|\\)/
      string.gsub(pattern){|match|"\\"  + match} # <-- Trying to take the currently found match and add a \ before it I have no idea how to do that).
    end

    def generate(template_name, template)
      IO.write("cfn/#{template_name}.rb", template)
      json = `ruby cfn/#{template_name}.rb expand`
      Dir.mkdir 'cfn' rescue Errno::ENOENT
      template_file_name = "#{env}-#{template_name}.cfn.json"
      IO.write("cfn/#{template_file_name}", json)
      puts "Created #{template_file_name} in the cfn directory"
      FileUtils.rm("cfn/#{template_name}.rb")
    end

    def upload_templates
      check_template_bucket
      templates = ['master','resources','beanstalk']
      templates.each do |template|
        filename = "cfn/#{env}-#{template}.cfn.json"
        key = File.basename(filename)
        s3.buckets["#{@options[:cfn_bucket]}/#{env}"].objects[key].write(:file => filename)
      end
      puts "templates uploaded"
    end

    def check_template_bucket
      bucket_name = "#{@options[:cfn_bucket]}/#{env}"
      if s3.buckets[bucket_name].exists?
        puts "uploading cfn templates to #{@options[:cfn_bucket]}/#{env}"
      else
        puts "creating bucket #{@options[:cfn_bucket]}/#{env} to upload templates"
        s3.buckets.create(bucket_name) 
      end
    end

    def create_aws_cfn_stack
      puts "Creating stack on aws..."
      stack = @cfm.stacks.create(@options[:stack_name], stack_template, :disable_rollback => true)
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
      if env.include?("prod")
        "prod"
      elsif env.include?("stag")
        "stag"
      else
        ""
      end
    end
  end
end

