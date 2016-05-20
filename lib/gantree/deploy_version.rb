require 'json'
require 'archive/zip'
require 'colorize'
require_relative 'notification'

module Gantree
  class DeployVersion < Deploy

    attr_reader :packaged_version, :dockerrun_file
    def initialize options, env
      @options = options
      @ext = @options[:ext]
      @ext_role = @options[:ext_role]
      @project_root = @options[:project_root]
      @dockerrun_file = "#{@project_root}Dockerrun.aws.json"
      @env = env
    end

    def run
      @packaged_version = create_version_files
    end

    def docker
      @docker ||= JSON.parse(IO.read(@dockerrun_file))  
    end

    def set_auth
      docker["Authentication"] = {}
      items = @options[:auth].split("/")
      bucket = items.shift
      key = items.join("/")
      docker["Authentication"]["Bucket"] = bucket
      docker["Authentication"]["Key"] = key
      IO.write("/tmp/#{@dockerrun_file}", JSON.pretty_generate(docker))
    end

    def set_tag_to_deploy
      image = docker["Image"]["Name"]
      token = image.split(":")
      if token.length == 3
        image = token[0] + (":") + token[1] + ":#{@options[:tag]}"
        docker["Image"]["Name"] = image
      elsif token.length == 2
        image.gsub!(/:(.*)$/, ":#{@options[:tag]}")
      else
        puts "Too many ':'".yellow
      end
      IO.write("/tmp/#{@dockerrun_file}", JSON.pretty_generate(docker))
    end

    def set_image_path
      image = docker["Image"]["Name"]
      image.gsub!(/(.*):/, "#{@options[:image_path]}:")
      path = "/tmp/#{@dockerrun_file}"
      FileUtils.mkdir_p(File.dirname(path)) unless File.exist?(path)
      IO.write(path, JSON.pretty_generate(docker))
      image
    end

    def version_tag
      @options[:tag] || tag
    end

    def create_version_files
      clean_up
      version = "#{version_tag}-#{Time.now.strftime("%m-%d-%Y-%H-%M-%S")}"
      puts "version: #{version}"
      set_auth if @options[:auth]
      set_image_path if @options[:image_path]
      set_tag_to_deploy
      if File.directory?(".ebextensions/") || @ext || @ext_role
        zip = "#{@project_root}#{version}.zip"
        merge_extensions
        puts "The following files are being zipped".yellow
        system('ls -l /tmp/merged_extensions/.ebextensions/')
        Archive::Zip.archive(zip, ['/tmp/merged_extensions/.ebextensions/', "/tmp/#{@dockerrun_file}"])
        zip
      else
        new_dockerrun = "/tmp/#{version}-Dockerrun.aws.json"
        FileUtils.cp("/tmp/Dockerrun.aws.json", new_dockerrun)
        new_dockerrun
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
      puts "Cleaning up tmp files".yellow
      FileUtils.rm_rf @packaged_version if @packaged_version
      FileUtils.rm_rf("/tmp/#{@ext.split('/').last}") if File.directory?("/tmp/#{@ext.split('/').last}")
      FileUtils.rm_rf("/tmp/#{@ext_role.split('/').last}:#{get_role_type}") if @ext_role
      FileUtils.rm_rf("/tmp/merged_extensions/") if File.directory? "/tmp/merged_extensions/"
      puts "All tmp files removed".green
    end
    
    def merge_extensions
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

