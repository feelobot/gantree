require 'thor'
require 'aws-sdk'

module Gantree

  class CLI < Thor
    desc "initialize IMAGE", "create a dockerrun for your IMAGE"
    method_option :user, :aliases => "-u", :desc => "user credentials for private repo"
    def init(image)
      puts "initialize image"
    end
  end
end
