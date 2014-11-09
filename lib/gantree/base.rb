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

    def default_name(app)
      [
       app.match(/^[a-zA-Z]*\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[1],
       app.match(/^([a-zA-Z]*)\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[1],
       app.match(/^([a-zA-Z]*)\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[3]
      ].join("-")
    end
  end
end

