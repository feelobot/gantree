require 'colorize'

module Gantree
  class App < Base

    def initialize env, options
      check_credentials
      set_aws_keys
      @env = env
    end

    def restart
      eb.restart_app_server({ environment_name: "#{@env}" })
      puts "App is now restarting".green
    end
  end
end

