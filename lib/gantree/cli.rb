require 'thor'
require 'aws-sdk'
require 'gantree/cli/help'

module Gantree
  class CLI < Thor

    desc "deploy APP", "deploy specified APP"
    option :branch, :desc => 'branch to deploy'
    method_option :tag, :aliases => "-t", :desc => "Set docker tag to deploy"
    def deploy app
      Gantree::Deploy.new(app, options).run
    end

    desc "init IMAGE", "create a dockerrun for your IMAGE"
    method_option :user, :aliases => "-u", :desc => "user credentials for private repo"
    method_option :port, :aliases => "-p", :desc => "port of running application"
    def init image
      Gantree::Init.new(image,options).run
    end
  end
end
