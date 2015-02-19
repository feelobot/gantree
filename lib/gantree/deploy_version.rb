require 'json'
require 'archive/zip'
require 'colorize'
require_relative 'notification'

module Gantree
  class DeployVersion < Deploy

    def initialize options
      @options = options
      @ext = @options[:ext]
      @dockerrun_file = "Dockerrun.aws.json"
    end

    def run
      create_version_files
    end

    def create_version_files
      unless ext?
        new_dockerrun = "#{version}-Dockerrun.aws.json"
        FileUtils.cp(@dockerrun_file, new_dockerrun)
        new_dockerrun
      else
        zip = "#{version}.zip"
        clone_repo if repo?
        Archive::Zip.archive(zip, ['.ebextensions/', @dockerrun_file])
        zip
      end
    end

    def set_tag_to_deploy
      docker = JSON.parse(IO.read(@dockerrun_file))
      image = docker["Image"]["Name"]
      image.gsub!(/:(.*)$/, ":#{@options[:tag]}")
      IO.write(@dockerrun_file, JSON.pretty_generate(docker))
    end

    def set_image_path
      docker = JSON.parse(IO.read(@dockerrun_file))
      image = docker["Image"]["Name"]
      image.gsub!(/(.*):/, "#{@options[:image_path]}:")
      IO.write(@dockerrun_file, JSON.pretty_generate(docker))
      image
    end

    def autodetect_app_role env
      enabled = @options[:autodetect_app_role]
      if enabled == true || enabled == "true"
        role = env.split('-')[2]
        puts "Deploying app as a #{role}"
        [{:option_name => "ROLE", :value => role, :namespace => "aws:elasticbeanstalk:application:environment" }]
      else 
        []
      end
    end

    def create_version_files
      time_stamp = Time.now.to_i
      branch = `git rev-parse --abbrev-ref HEAD`
      puts "branch: #{branch}"
      hash = `git rev-parse --verify --short #{branch}`.strip
      puts "hash #{hash}"
      version = "#{@app}-#{hash}-#{time_stamp}"
      puts "version: #{version}"
      #auto_detect_app_role if @options[:autodetect_app_role] == true
      set_image_path if @options[:image_path]
      set_tag_to_deploy if @options[:tag]
      unless ext?
        new_dockerrun = "#{version}-Dockerrun.aws.json"
        FileUtils.cp("Dockerrun.aws.json", new_dockerrun)
        new_dockerrun
      else
        zip = "#{version}.zip"
        clone_repo if repo?
        Archive::Zip.archive(zip, ['.ebextensions/', @dockerrun_file])
        zip
      end
    end

    def ext?
      if @ext
        true
      else
        false
      end
    end

    def repo?
      if @ext.include? "github"
        puts "Cloning: #{@ext}..."
        true
      else
        false
      end
    end

    def local?
      File.directory?(@ext)
    end

    def get_ext_repo
      if ext_branch?
        @ext.sub(":#{get_ext_branch}", '')
      else
        @ext
      end
    end

    def ext_branch?
      if @ext.count(":") == 2
        true
      else
        false
      end
    end

    def get_ext_branch
      branch = @ext.match(/:.*(:.*)$/)[1]
      branch.tr(':','')
    end

    def clone_repo
      if ext_branch?
        `git clone -b #{get_ext_branch} #{get_ext_repo}`
      else
        `git clone #{get_ext_repo}`
      end
    end

    def clean_up
      FileUtils.rm_rf(@packaged_version)
      `git checkout Dockerrun.aws.json` # reverts back to original Dockerrun.aws.json
      `rm -rf .ebextensions/` if self.ext?
    end
  end
end

