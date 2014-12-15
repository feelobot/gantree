require 'cloudformation-ruby-dsl'
require 'highline/import'
require_relative 'cfn/master'
require_relative 'cfn/beanstalk'
require_relative 'cfn/resources'

module Gantree
  class Create < Base
    attr_reader :env, :stack_name

    def initialize stack_name,options
      check_credentials
      set_aws_keys

      @requirements = "#!/usr/bin/env ruby
        require 'cloudformation-ruby-dsl/cfntemplate'
        require 'cloudformation-ruby-dsl/spotprice'
        require 'cloudformation-ruby-dsl/table'"

      additional_options = {
        requirements: @requirements,
        stack_name: stack_name,
        stack_hash: (0...8).map { (65 + rand(26)).chr }.join
      }
      @options = options.merge(additional_options)
      @options[:env] ||= create_default_env
      @options[:env_type] ||= env_type
      @options[:solution] ||= get_latest_docker_solution
      @templates = ['master','resources','beanstalk']
    end

    def run
      @options[:rds_enabled] = rds_enabled? if @options[:rds] 
      print_options
      create_cfn_if_needed
      create_all_templates unless @options[:local]
      upload_templates unless @options[:dry_run]
      create_aws_cfn_stack unless @options[:dry_run]
    end

    def stack_template
      s3.buckets["#{@options[:cfn_bucket]}/#{@options[:stack_name]}"].objects["#{@options[:stack_name]}-master.cfn.json"]
    end

    def create_cfn_if_needed
      Dir.mkdir 'cfn' unless File.directory?("cfn")
    end

    def create_all_templates
      @options[:dupe] ? duplicate_stack : generate_all_templates
    end

    def generate_all_templates
      puts "Generating templates from gantree"
      generate("master", MasterTemplate.new(@options).create)
      generate("beanstalk", BeanstalkTemplate.new(@options).create)
      generate("resources", ResourcesTemplate.new(@options).create)
    end

    def duplicate_stack
      puts "Duplicating cluster"
      orgin_stack_name = @options[:dupe]
      @templates.each do |template|
        FileUtils.cp("cfn/#{orgin_stack_name}-#{template}.cfn.json", "cfn/#{@options[:stack_name]}-#{template}.cfn.json")
        file = IO.read("cfn/#{@options[:stack_name]}-#{template}.cfn.json")
        file.gsub!(/#{escape_characters_in_string(orgin_stack_name)}/, @options[:stack_name])
        replace_env_references(file)
        IO.write("cfn/#{@options[:stack_name]}-#{template}.cfn.json",file)
      end
    end
    
    def generate(template_name, template)
      IO.write("cfn/#{template_name}.rb", template)
      json = `ruby cfn/#{template_name}.rb expand`
      Dir.mkdir 'cfn' rescue Errno::ENOENT
      template_file_name = "#{@options[:stack_name]}-#{template_name}.cfn.json"
      IO.write("cfn/#{template_file_name}", json)
      puts "Created #{template_file_name} in the cfn directory"
      FileUtils.rm("cfn/#{template_name}.rb")
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
      bucket_name = "#{@options[:cfn_bucket]}/#{@options[:stack_name]}"
      if s3.buckets[bucket_name].exists?
        puts "uploading cfn templates to #{@options[:cfn_bucket]}/#{@options[:stack_name]}"
      else
        puts "creating bucket #{@options[:cfn_bucket]}/#{@options[:stack_name]} to upload templates"
        s3.buckets.create(bucket_name) 
      end
    end

    def create_aws_cfn_stack
      puts "Creating stack on aws..."
      stack = @cfm.stacks.create(@options[:stack_name], stack_template, { 
        :disable_rollback => true, 
        :tags => [
          { key: "StackName", value: @options[:stack_name] },
        ]})
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
  end
end

