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
      @requirements = "#!/usr/bin/env ruby
        require 'cloudformation-ruby-dsl/cfntemplate'
        require 'cloudformation-ruby-dsl/spotprice'
        require 'cloudformation-ruby-dsl/table'"

      additional_options = {
        stack_name: stack_name,
        requirements: @requirements,
        cfn_bucket: "br-templates",
        domain: "brenv.net.",
        stack_hash: (0...8).map { (65 + rand(26)).chr }.join
      }
      @options = options.merge(additional_options)
      @options[:env] ||= create_default_env
      @options[:env_type] ||= env_type
    end

    def create_default_env
      tags = @options[:stack_name].split("-")
      if tags.length == 3
        env = [tags[1],tags[0],"app",tags[2]].join('-')
      else
        raise "Please Set Envinronment Name with -e"
      end
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
      add_role @options[:role] if @options[:role]
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
      s3.buckets["#{@options[:cfn_bucket]}/#{@options[:stack_name]}"].objects["#{@options[:stack_name]}-master.cfn.json"]
    end

    def create_cfn_if_needed
      Dir.mkdir 'cfn' unless File.directory?("cfn")
    end

    def create_all_templates
      if @options[:dupe]
        puts "Duplicating cluster"
        orgin_stack_name = @options[:dupe]
        templates = ['master','resources','beanstalk']
        templates.each do |template|
          FileUtils.cp("cfn/#{orgin_stack_name}-#{template}.cfn.json", "cfn/#{@options[:stack_name]}-#{template}.cfn.json")
          file = IO.read("cfn/#{@options[:stack_name]}-#{template}.cfn.json")
          file.gsub!(/#{escape_characters_in_string(orgin_stack_name)}/, @options[:stack_name])
          replace_env_references(file)
          IO.write("cfn/#{@options[:stack_name]}-#{template}.cfn.json",file)
        end
      else
        puts "Generating templates from gantree"
        generate("master", MasterTemplate.new(@options).create)
        generate("beanstalk", BeanstalkTemplate.new(@options).create)
        generate("resources", ResourcesTemplate.new(@options).create)
      end
    end

    def replace_env_references file
      origin_tags = @options[:dupe].split("-")
      new_tags = @options[:stack_name].split("-")
      possible_roles = ["app","worker","listener","djay","scheduler"]
      possible_roles.each do |role|
        origin_env = [origin_tags[1],origin_tags[0],role,origin_tags[2]].join('-')
        new_env = [new_tags[1],new_tags[0],role,new_tags[2]].join('-')
        file.gsub!(/#{escape_characters_in_string(origin_env)}/, new_env)
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
      template_file_name = "#{@options[:stack_name]}-#{template_name}.cfn.json"
      IO.write("cfn/#{template_file_name}", json)
      puts "Created #{template_file_name} in the cfn directory"
      FileUtils.rm("cfn/#{template_name}.rb")
    end

    def upload_templates
      check_template_bucket
      templates = ['master','resources','beanstalk']
      templates.each do |template|
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

    def env_type
      if @options[:env].include?("prod")
        "prod"
      elsif @options[:env].include?("stag")
        "stag"
      else
        ""
      end
    end

    def add_role name
      env = @options[:env].sub('app', name)
      beanstalk = JSON.parse(IO.read("cfn/#{@options[:stack_name]}-beanstalk.cfn.json"))
      unless beanstalk["Resources"][name] then
        role = {
          "Type" => "AWS::ElasticBeanstalk::Environment",
          "Properties"=> {
            "ApplicationName" => "#{@options[:stack_name]}",
            "EnvironmentName" => "#{env}",
            "Description" => "#{name} Environment",
            "TemplateName" => {
              "Ref" => "ConfigurationTemplate"
            },
            "OptionSettings" => []
          }
        }
        #puts JSON.pretty_generate role
        beanstalk["Resources"]["#{name}".to_sym] = role
        IO.write("cfn/#{@options[:stack_name]}-beanstalk.cfn.json", JSON.pretty_generate(beanstalk))
        puts JSON.pretty_generate(beanstalk["Resources"].to_a.last)
        puts "Added new #{name} role".green
      else 
        puts "Role already exists".red
      end
    end
  end
end

