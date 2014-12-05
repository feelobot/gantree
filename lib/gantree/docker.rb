require 'colorize'

module Gantree
  class Docker < Base

    def initialize options
      check_credentials
      set_aws_keys
      @options = options
      @hub = @options[:hub]
      raise "Please provide a hub name in your .gantreecfg ex { hub : 'bleacher' }" unless @hub
      @repo = `basename $(git rev-parse --show-toplevel)`.strip
      @tag = @options[:tag] ||= tag
    end

    def build 
      puts "Building..."
      output = `docker build -t #{@hub}/#{@repo}:#{@tag} .`
      if $?.success?
        puts "Image Built: #{@hub}/#{@repo}:#{@tag}".green 
        puts "docker push #{@hub}/#{@repo}:#{@tag}" unless @options[:hush]
        puts "gantree deploy app_name -t #{@tag}" unless @options[:hush]
      else
        puts "Error: Image was not built successfully".red
        puts "#{output}"
        exit 1
      end
    end

    def push 
      puts "Pushing..."
      output = `docker push #{@hub}/#{@repo}:#{@tag}`
      if $?.success?
        puts "Image Pushed: #{@hub}/#{@repo}:#{@tag}".green 
        puts "gantree deploy app_name -t #{@tag}" unless @options[:hush]
      else
        puts "Error: Image was not pushed successfully".red
        puts "#{output}"
        exit 1
      end
    end
  end
end

