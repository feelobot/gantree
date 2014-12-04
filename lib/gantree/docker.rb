require 'colorize'

module Gantree
  class Docker < Base

    def initialize options
      check_credentials
      set_aws_keys
      @options = options
      @hub = @options[:hub] ||= "bleacher"
      @origin = `git remote show origin | grep "Push" | cut -f1 -d"/" | cut -d":" -f3`.strip
      @repo = `basename $(git rev-parse --show-toplevel)`.strip
      @branch = `git rev-parse --abbrev-ref HEAD`.strip
      @hash = `git rev-parse --verify --short #{@branch}`.strip
    end

    def build 
      puts "Building..."
      `docker build -t #{@hub}/#{@repo}:#{@origin}-#{@branch}-#{@hash} .`
      puts "Image Built: #{@hub}/#{@repo}:#{@origin}-#{@branch}-#{@hash}".green if $?.success?
      puts "docker push #{@hub}/#{@repo}:#{@origin}-#{@branch}-#{@hash}"
      puts "gantree deploy app_name -t #{@origin}-#{@branch}-#{@hash}"
    end
  end
end
