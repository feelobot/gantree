require 'colorize'

module Gantree
  class Update < Base

    def initialize stack_name,options
      check_credentials
      set_aws_keys
      @options = options
      @options[:stack_name] = stack_name 
      @options[:env] ||= create_default_env
      @options[:env_type] ||= env_type
      @templates = ['master','resources','beanstalk']
    end

    def run
      puts "Updating stack from local cfn repo"
      add_role @options[:role] if @options[:role]
      change_solution_stack if @options[:solution]
      return if @options[:dry_run]
      upload_templates
      puts "Stack Updated".green if cfm.stacks[@options[:stack_name]].update(:template => stack_template)
    end

    def stack_template
      s3.buckets["#{@options[:cfn_bucket]}/#{@stack_name}"].objects["#{@stack_name}-master.cfn.json"]
    end

    def change_solution_stack 
      beanstalk = JSON.parse(IO.read("cfn/#{@options[:stack_name]}-beanstalk.cfn.json"))
      solution_stack = set_solution_stack
      beanstalk["Resources"]["ConfigurationTemplate"]["Properties"]["SolutionStackName"] = solution_stack
      beanstalk["Resources"]["ConfigurationTemplate"]["Properties"]["Description"] = solution_stack
      IO.write("cfn/#{@options[:stack_name]}-beanstalk.cfn.json",JSON.pretty_generate(beanstalk))
      puts "Updated solution to #{solution_stack}".green
    end

    def set_solution_stack
      @options[:solution] == "latest" ? get_latest_docker_solution : @options[:solution]
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
        IO.write("cfn/#{@options[:stack_name]}-beanstalk.cfn.json", JSON.pretty_generate(beanstalk)) unless @options[:dry_run]
        puts JSON.pretty_generate(beanstalk["Resources"].to_a.last)
        puts "Added new #{name} role".green
      else 
        puts "Role already exists".red
      end
    end
  end
end

