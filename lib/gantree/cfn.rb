require 'cloudformation-ruby-dsl'
require_relative 'cfn/master'
require_relative 'cfn/beanstalk'
require_relative 'cfn/resources'

module Gantree
  class Stack
    def initialize stack_name
      AWS.config(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCES_KEY'])
      @requirements = "#!/usr/bin/env ruby
        require 'bundler/setup'
        require 'cloudformation-ruby-dsl/cfntemplate'
        require 'cloudformation-ruby-dsl/spotprice'
        require 'cloudformation-ruby-dsl/table'"
      @params = {
        stack_name: stack_name,
        requirements: @requirements,
        cfn_bucket: "br-templates",
        env: "knarr-stag-s3"
      }
    end

    def create
      generate("master", MasterTemplate.new(@params).create)
      generate("beanstalk", BeanstalkTemplate.new(@params).create)
      generate("resources", ResourcesTemplate.new(@params).create)
    end

    def upload_tempaltes_to_s3
    end

    def create_aws_cfn_stack
    end

    def generate(template_name, template)
      IO.write("cfn/#{template_name}.rb", template)
      json = `ruby cfn/#{template_name}.rb expand`
      Dir.mkdir 'cfn' rescue Errno::ENOENT
      template_file_name = "#{@params[:env]}-#{template_name}.cfn.json"
      IO.write("cfn/#{template_file_name}", json)
      puts "Created #{template_file_name} in the cfn directory"
      FileUtils.rm("cfn/#{template_name}.rb")
    end
  end
end
