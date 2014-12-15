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

    def cfm
      @cfm ||= AWS::CloudFormation.new
    end


    def tag
      origin = `git config --get remote.origin.url`.match(":(.*)\/")[1]
      branch = `git rev-parse --abbrev-ref HEAD`.strip
      hash = `git rev-parse --verify --short #{branch}`.strip
      "#{origin}-#{branch}-#{hash}"
    end

    def create_default_env
      tags = @options[:stack_name].split("-")
      if tags.length == 3
        env = [tags[1],tags[0],"app",tags[2]].join('-')
      else
        raise "Please Set Envinronment Name with -e"
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

    def get_latest_docker_solution
      result = eb.list_available_solution_stacks
      solutions = result[:solution_stacks]
      docker_solutions = solutions.select { |s|  s.include? "running Docker"}
      docker_solutions.first
    end

    
    def escape_characters_in_string(string)
      pattern = /(\'|\"|\.|\*|\/|\-|\\)/
      string.gsub(pattern){|match|"\\"  + match} # <-- Trying to take the currently found match and add a \ before it I have no idea how to do that).
    end

  end
end

