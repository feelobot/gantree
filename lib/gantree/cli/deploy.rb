require 'thor'
require 'gantree/cli/help'

module Gantree

  class CLI < Thor
    class_option :verbose, :type => :boolean

    desc "deploy APP", "deploy specified APP"
    option :branch, :desc => 'branch to deploy'
    option :tag,    :desc => 'set image tag'
    def deploy(app)
      puts "Deploying #{app}"
    end
  end
end
