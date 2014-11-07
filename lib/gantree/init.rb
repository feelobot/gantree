require 'thor'
require 'aws-sdk-v1'

module Gantree
  class Init < Base
    attr_reader :image, :options, :bucket_name

    def initialize image, options
      check_credentials
      set_aws_keys

      @image = image
      @options = options
      @bucket_name  = @options.bucket || "docker-cfgs"
    end

    def run
      puts "initialize image #{@image}"
      print_options

      FileUtils.rm("Dockerrun.aws.json") if File.exist?("Dockerrun.aws.json")
      create_docker_config_folder unless options[:dry_run]
      create_dockerrun
      upload_docker_config if options.user && !options[:dry_run]
    end

    private
    def create_docker_config_folder
      bucket = s3.buckets.create(bucket_name) unless s3.buckets[bucket_name].exists?
    end

    def dockerrun_object
      docker = {
        AWSEBDockerrunVersion: "1",
        Image: {
          Name: image,
          Update: true
        },
        Logging: "/var/log/nginx",
        Ports: [
          {
            ContainerPort: options.port
          }
        ]
      }
      if options.user
        docker["Authentication"] = {
          Bucket: bucket_name,
          Key: "#{options.user}.dockercfg"
        }
      end
      docker
    end

    def create_dockerrun
      IO.write("Dockerrun.aws.json", JSON.pretty_generate(dockerrun_object))
    end

    def upload_docker_config
      raise "You need to run 'docker login' to generate a .dockercfg file" unless dockercfg_file_exist?
      filename = "#{ENV['HOME']}/#{options.user}.dockercfg"
      FileUtils.cp("#{ENV['HOME']}/.dockercfg", "#{ENV['HOME']}/#{options.user}.dockercfg")
      key = File.basename(filename)
      s3.buckets[bucket_name].objects[key].write(:file => filename)
    end

    def dockercfg_file_exist?
      File.exist?("#{ENV['HOME']}/.dockercfg")
    end
  end
end

