require 'thor'
require 'gantree/cli/help'

module Gantree

  class CLI < Thor
    class_option :verbose, :type => :boolean

    desc "hello NAME", "say hello to NAME"
    option :from, :desc => 'from person'
    def hello(name)
      puts "from: #{options[:from]}" if options[:from]
      puts "Hello #{name}"
    end

    desc "fetch <repository> [<refspec>...]", "Download objects and refs from another repository"
    options :all => :boolean, :multiple => :boolean
    option :append, :type => :boolean, :aliases => :a, :desc => 'desc'
    def fetch(respository, *refspec)
      # implement git fetch here
    end
 
  end
end