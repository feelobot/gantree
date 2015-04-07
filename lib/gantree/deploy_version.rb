require 'json'
require 'archive/zip'
require 'colorize'
require_relative 'notification'

module Gantree
  class DeployVersion < Deploy

    def initialize options, env
      @options = options
      @ext = @options[:ext]
      @ext_role = @options[:ext_role]
      @dockerrun_file = "Dockerrun.aws.json"
      @env = env
    end

    def run
      @packaged_version = create_version_files
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

    def create_version_files
      version = "#{tag}-#{Time.now.strftime("%b-%d-%Y-%a-%H-%M-%S")}"
      puts "version: #{version}"
      set_image_path if @options[:image_path]
      set_tag_to_deploy if @options[:tag]
      if File.directory?(".ebextensions/") || @ext || @ext_role
        zip = "#{version}.zip"
        merge_extensions
        puts "The following files are being zipped".yellow
        system('ls -l /tmp/merged_extensions/.ebextensions/')
        Archive::Zip.archive(zip, ['/tmp/merged_extensions/.ebextensions/', @dockerrun_file])
        zip
      else
        new_dockerrun = "#{version}-Dockerrun.aws.json"
        FileUtils.cp("Dockerrun.aws.json", new_dockerrun)
        new_dockerrun
      end
    rescue => e
      puts e
      clean_up
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

    def local_extensions?
      File.directory?(".ebextensions/")
    end

    def get_ext_repo repo
      if ext_branch? repo
        repo.sub(":#{get_ext_branch repo}", '')
      else
        repo
      end
    end

    def ext_branch? repo
      if repo.count(":") == 2
        true
      else
        false
      end
    end

    def get_ext_branch repo
      branch = repo.match(/:.*(:.*)$/)[1]
      branch.tr(':','')
    end

    def clone_repo repo
      repo_name = repo.split('/').last
      FileUtils.mkdir("/tmp/#{repo_name}")
      if ext_branch? repo
        `git clone -b #{get_ext_branch repo} #{get_ext_repo repo} /tmp/#{repo_name}/`
      else
        `git clone #{get_ext_repo repo} /tmp/#{repo_name}/`
      end
      FileUtils.cp_r "/tmp/#{repo_name}/.", "/tmp/merged_extensions/.ebextensions/"
    end

    def clean_up
      `rm -rf #{@packaged_version}` if @packaged_version
      `git checkout Dockerrun.aws.json` # reverts back to original Dockerrun.aws.json
      FileUtils.rm_rf("/tmp/#{@ext.split('/').last}")
      FileUtils.rm_rf("/tmp/#{@ext_role.split('/').last}:#{get_role_type}")
      FileUtils.rm_rf("/tmp/merged_extensions/")
    rescue => e
      puts "Warning: had some trouble cleaning up".yellow
      puts e
    end
    
    def merge_extensions
      clean_up
      FileUtils.mkdir("/tmp/merged_extensions/")
      FileUtils.mkdir("/tmp/merged_extensions/.ebextensions/")
      clone_repo @ext if @ext
      clone_repo "#{@ext_role}:#{get_role_type}" if @ext_role
      FileUtils.cp_r('.ebextensions/.','/tmp/merged_extensions/.ebextensions') if File.directory? ".ebextensions/"
    end
    def get_role_type
      @env.split('-')[2]
    end
  end
end

