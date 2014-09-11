require 'cloudformation-ruby-dsl'
require_relative 'cfn/master'
require_relative 'cfn/beanstalk'
require_relative 'cfn/resources'

module Gantree
  class Stack
    def initialize stack_name,options
      AWS.config(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCES_KEY'])
      @s3 = AWS::S3.new
      @requirements = "#!/usr/bin/env ruby
        require 'bundler/setup'
        require 'cloudformation-ruby-dsl/cfntemplate'
        require 'cloudformation-ruby-dsl/spotprice'
        require 'cloudformation-ruby-dsl/table'"
      @stack_name = stack_name
      @env = options[:env] || stack_name.match(/^[a-zA-Z]*\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[1] + "-" + stack_name.match(/^([a-zA-Z]*)\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[1] + '-' + stack_name.match(/^([a-zA-Z]*)\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[3]
      @params = {
        stack_name: @stack_name,
        requirements: @requirements,
        cfn_bucket: "br-templates",
        env: @env
      }
    end

    def create
      generate("master", MasterTemplate.new(@params).create)
      generate("beanstalk", BeanstalkTemplate.new(@params).create)
      generate("resources", ResourcesTemplate.new(@params).create)
    end

    def generate(template_name, template)
      IO.write("cfn/#{template_name}.rb", template)
      json = `ruby cfn/#{template_name}.rb expand`
      Dir.mkdir 'cfn' rescue Errno::ENOENT
      template_file_name = "#{@params[:env]}-#{template_name}.cfn.json"
      IO.write("cfn/#{template_file_name}", json)
      puts "Created #{template_file_name} in the cfn directory"
      FileUtils.rm("cfn/#{template_name}.rb")
      upload_template_to_s3("cfn/#{template_file_name}")
    end

    def upload_template_to_s3(filename)
      begin
        puts "uploading cfn template to #{@params[:cfn_bucket]}/#{@env}"
        key = File.basename(filename)
        @s3.buckets["#{@params[:cfn_bucket]}/#{@env}"].objects[key].write(:file => filename)
      rescue AWS::S3::Errors::NoSuchBucket
        puts "bucket didn't exist...creating"
        bucket = @s3.buckets.create("#{@params[:cfn_bucket]}/#{@env}")
        retry
      rescue AWS::S3::Errors::AccessDenied
        puts "Your key is not configured for s3 access, please let your operations team know"
      end
    end

    def create_aws_cfn_stack
      puts "Creating stack on aws..."
      cfm = AWS::CloudFormation.new
      stack = cfm.stacks.create(stack_name, template)
    end

  end
end
