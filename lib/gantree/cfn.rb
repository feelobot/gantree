require 'cloudformation-ruby-dsl'
require_relative 'cfn/master'
require_relative 'cfn/beanstalk'
require_relative 'cfn/resources'

module Gantree
  class Cfn
    def initialize app,options
      @options = options
      AWS.config(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCES_KEY'])
    end

    def update

    end

    def create
      MasterTemplate.generate(@options)
      BeanstalkTemplate.generate(@options)
      ResourceTemplate.generate(@options)
      upload_templates_to_s3
    end

    def upload_tempaltes_to_s3

    end
  end
end
