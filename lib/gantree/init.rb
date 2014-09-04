require 'thor'
require 'aws-sdk'

module Gantree

  class Init
    def initialize image,options
      @image = image
      @options = options
      @s3 = AWS.s3.new
    end

    def run
      puts "initialize image #{@image}"
      puts "with user #{@options.user}" if @options.user
      FileUtils.rm("Dockerrun.aws.json") if File.exist?("Dockerrun.aws.json")
      create_docker_config_folder
      create_dockerrun
      upload_docker_config if @options.user
    end

    def create_docker_config_folder
      bucket = @s3.buckets.create("docker-cfgs")
    end

    def dockerrun_object
      docker = {
        AWSEBDockerrunVersion: "1",
        Image: {
          Name: @image,
          Update: true
        },
        Ports: [
          {
            "ContainerPort": @options.port
          }
        ]
      }
      if @options.user
        docker.Authentication = {
          "Bucket": "docker-cfgs",
          "Key": "#{@options.user}.dockercfg"
        }
      end
    end

    def create_dockerrun
      IO.write("Dockerrun.aws.json",JSON.pretty_generate(dockerrun_object))
    end

    def upload_docker_config
      FileUtils.cp("~/.dockercfg", "~/#{@options.user}.dockercfg")
      key = File.basename("~/#{@options.user}.dockercfg")
      @s3.buckets["docker-cfgs"].objects[key].write(:file => filename)
    end

  end
end
