require 'thor'
require 'aws-sdk'

module Gantree

  class Init
    def initialize image,options
      @image = image
      @options = merge_defaults(options)
      AWS.config(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
      @s3 = AWS::S3.new
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
        Logging: "/var/log/nginx",
        Ports: [
          {
            ContainerPort: @options.port
          }
        ]
      }
      if @options.user
        docker["Authentication"] = {
          Bucket: "docker-cfgs",
          Key: "#{@options.user}.dockercfg"
        }
      end
      docker
    end

    def create_dockerrun
      IO.write("Dockerrun.aws.json",JSON.pretty_generate(dockerrun_object))
    end

    def upload_docker_config
      raise "You need to run 'docker login' to generate a .dockercfg file" if File.exist?("#{ENV['HOME']}/.dockercfg") != true
      filename = "#{ENV['HOME']}/#{@options.user}.dockercfg"
      FileUtils.cp("#{ENV['HOME']}/.dockercfg", "#{ENV['HOME']}/#{@options.user}.dockercfg")
      key = File.basename(filename)
      @s3.buckets["docker-cfgs"].objects[key].write(:file => filename)
    end

    def merge_defaults(options)
      if File.exist?(".gantreecfg")
        defaults = JSON.parse(File.open(".gantreecfg").read)
        defaults.merge(options)
      else
        options
      end
    end
  end
end
