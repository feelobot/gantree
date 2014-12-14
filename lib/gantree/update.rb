require 'colorize'

module Gantree
  class Update < Base
    attr_reader :stack_name

    def initialize stack_name,options
      check_credentials
      set_aws_keys
      @options[:env] ||= create_default_env
      @options[:env_type] ||= env_type(env)
    end


    def run
      puts "Updating stack from local cfn repo"
      add_role @options[:role] if @options[:role]
      change_solution_stack if @options[:solution]
      return if @options[:dry_run]
      upload_templates
      puts "Stack Updated".green if @cfm.stacks[@options[:stack_name]].update(:template => stack_template)
    end

    def stack_template
      s3.buckets["#{@options[:cfn_bucket]}/#{@stack_name}"].objects["#{@stack_name}-master.cfn.json"]
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

    def change_solution_stack 
      beanstalk = JSON.parse(IO.read("cfn/#{@options[:stack_name]}-beanstalk.cfn.json"))
      solution_stack = set_solution_stack
      beanstalk["Resources"]["ConfigurationTemplate"]["Properties"]["SolutionStackName"] = solution_stack
      beanstalk["Resources"]["ConfigurationTemplate"]["Properties"]["Description"] = solution_stack
      IO.write("cfn/#{@options[:stack_name]}-beanstalk.cfn.json",JSON.pretty_generate(beanstalk))
    end

    def set_solution_stack
      @options[:solution] == "latest" ? get_latest_docker_solution : @options[:solution]
    end

    def get_latest_docker_solution
      result = eb.list_available_solution_stacks
      solutions = result[:solution_stacks]
      docker_solutions = solutions.select { |s|  s.include? "running Docker"}
      docker_solutions.first
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

