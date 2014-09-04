require 'thor'
require 'aws-sdk'
require 'gantree/cli/help'

module Gantree
  class CLI < Thor
    AWS.config(
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCES_KEY'])

    desc "deploy APP", "deploy specified APP"
    option :branch, :desc => 'branch to deploy'
    method_option :tag, :aliases => "-t", :desc => "Set docker tag to deploy"
    def deploy app
      Gantree::Deploy.new(options.clone).run
    end

    desc "init IMAGE", "create a dockerrun for your IMAGE"
    method_option :user, :aliases => "-u", :desc => "user credentials for private repo"
    def init image
      Gantree::Init.new(options.clone).run
    end
  end
end
