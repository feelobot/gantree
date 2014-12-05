module Gantree
  class Base
    def check_credentials
      raise "Please set your AWS Environment Variables" unless ENV['AWS_SECRET_ACCESS_KEY']
      raise "Please set your AWS Environment Variables" unless ENV['AWS_ACCESS_KEY_ID']
    end

    def print_options
      @options.each do |param, value|
        puts "#{param}: #{value}"
      end
    end

    def set_aws_keys
      AWS.config(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
      )
    end

    def s3
      @s3 ||= AWS::S3.new
    end

    def eb
      @eb ||= AWS::ElasticBeanstalk::Client.new
    end

    def tag
      origin = `git remote show origin | grep "Push" | cut -f1 -d"/" | cut -d":" -f3`.strip
      branch = `git rev-parse --abbrev-ref HEAD`.strip
      hash = `git rev-parse --verify --short #{branch}`.strip
      "#{origin}-#{branch}-#{hash}"
    end
  end
end

