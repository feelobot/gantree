require 'thor'
require 'aws-sdk'

module Gantree

  class Init
    def initialize options
      @options = options
    end

    def run
      puts "initialize image #{@options.image}"
    end
  end
end
