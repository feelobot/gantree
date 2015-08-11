require 'colorize'

module Gantree
  class Docker < Base

    def initialize options
      check_credentials
      set_aws_keys
      @options = options
      @image_path = @options[:image_path] 
      @image_path||= get_image_path
      @tag = @options[:tag] ||= tag
      @base_image_tag = @options[:base_image_tag]
    end

    def get_image_path
      dockerrun = JSON.parse(IO.read("Dockerrun.aws.json"))
      image = dockerrun["Image"]["Name"]
      image.gsub!(/:(.*)$/, "") if image.include? ":"
      puts "Image Path: #{image}".light_blue
      image
    end
    
    def pull
      puts "Pulling Image First..."
      if @base_image_tag
        puts "Pulled Image: #{@image_path}:#{@base_image_tag}".green if system("docker pull #{@image_path}:#{@base_image_tag}")
      elsif system("docker pull #{@image_path}")
        puts "Pulled Image: #{@image_path}".green
      else 
        puts "Failed to Pull Image #{@image_path}".red
      end
    end

    def build
      puts "Building..."
      
      if system("git rev-parse --short HEAD > version.txt")
        puts "Outputting short hash to version.txt"
      else
        puts "Error: Could not output commit hash to version.txt (is this a git repository?)"
      end

      if system("docker build -t #{@image_path}:#{@tag} .")
        puts "Image Built: #{@image_path}:#{@tag}".green
        puts "gantree push --image-path #{@image_path} -t #{@tag}" unless @options[:hush]
        puts "gantree deploy app_name -t #{@tag}" unless @options[:hush]
      else
        puts "Error: Image was not built successfully".red
        exit 1
      end

      if system("rm -f version.txt")
        puts "Removing version.txt after docker build"
      else
        puts "Error: Can't remove version.txt after docker build"
      end
    end

    def push
      puts "Pushing to #{@image_path}:#{@tag} ..."
      if system("docker push #{@image_path}:#{@tag}")
        puts "Image Pushed: #{@image_path}:#{@tag}".green
        puts "gantree deploy app_name -t #{@tag}" unless @options[:hush]
      else
        puts "Error: Image was not pushed successfully".red
        exit 1
      end
    end
  end
end

