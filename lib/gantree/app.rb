require 'colorize'

module Gantree
  class App < Base
    attr_reader :app, :env

    def initialize app, options
      check_credentials
      set_aws_keys
      @options = options
      @app = @options[:env] || default_name(app)
      @env = app
    end

    def restart
      eb.restart_app_server({environment_name: "#{@env}"})
      puts "App is now restarting".green
    end

    private
    def eb
      @eb ||= AWS::ElasticBeanstalk::Client.new
    end
  end
end

