require "colorize"

module Gantree
  class Docker < Base
    def initialize(options)
      check_credentials
      set_aws_keys
      @options = options
      @image_path = @options[:image_path]
      raise "Please provide an image path name in .gantreecfg ex. { 'image_path' : 'bleacher/cms' }" unless @image_path
      @tag = @options[:tag] ||= tag
    end

    def build
      puts "Building..."
      output = `docker build -t #{@image_path}:#{@tag} .`
      if $?.success?
        puts "Image built: #{@image_path}:#{@tag}".green
        puts "gantree push --image-path #{@image_path} -t #{@tag}" unless @options[:hush]
        puts "gantree deploy app_name -t #{@tag}" unless @options[:hush]
      else
        puts "ERROR: Image was not successfully built".red
        puts "#{output}"
        exit 1
      end
    end

    def push
      puts "Pushing to #{@image_path}:#{@tag} ..."
      output = `docker push #{@image_path}:#{@tag}`
      if $?.success?
        puts "Image pushed: #{@image_path}:#{@tag}".green
        puts "gantree deploy app_name -t #{@tag}" unless @options[:hush]
      else
        puts "ERROR: Image was not successfully pushed".red
        puts "#{output}"
        exit 1
      end
    end
  end
end
