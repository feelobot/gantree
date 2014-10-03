require 'archive/zip'

module Gantree
  class Deploy

    def initialize app,options
      @options = options
      @ext = @options[:ext]
      AWS.config(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
      @app = @options[:env] || app.match(/^[a-zA-Z]*\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[1] + "-" + app.match(/^([a-zA-Z]*)\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[1] + '-' + app.match(/^([a-zA-Z]*)\-([a-zA-Z]*)\-[a-zA-Z]*\-([a-zA-Z]*\d*)/)[3]
      @env = app
      @eb = AWS::ElasticBeanstalk::Client.new
      @s3 = AWS::S3.new
      @tag = options.tag
    end

    def run
      puts "Deploying #{@app}"
      @packeged_version = create_version_files
      upload_to_s3
      create_eb_version
      update_application
    end

    private

    def upload_to_s3
      key = File.basename(@packeged_version)
      check_version_bucket
      puts "uploading version to #{@app}-versions"
      @s3.buckets["#{@app}-versions"].objects[key].write(:file => @packeged_version)
      FileUtils.rm(@packeged_version)
    end

    def create_eb_version
      begin
        @eb.create_application_version({
          :application_name => @app,
          :version_label => @packeged_version,
          :source_bundle => {
            :s3_bucket => "#{@app}-versions",
            :s3_key => @packeged_version
          }
        })
      rescue AWS::ElasticBeanstalk::Errors::InvalidParameterValue
        puts "Version already exists, recreating..."
        begin 
          @eb.delete_application_version({
            :application_name => @app,
            :version_label => @packeged_version,
            :delete_source_bundle => false
          })
          retry
        rescue AWS::ElasticBeanstalk::Errors::InvalidParameterValue
          puts "No Application named #{@app} found"
        end
      end
    end

    def update_application
      begin
        @eb.update_environment({
          :environment_name => @env,
          :version_label => @packeged_version
        })
      rescue AWS::ElasticBeanstalk::Errors::InvalidParameterValue
        puts "#{@env} doesn't exist"
      end
    end

    def create_version_files
      branch = `git rev-parse --abbrev-ref HEAD`
      puts "branch: #{branch}"
      hash = `git rev-parse --verify --short #{branch}`.strip
      puts "hash #{hash}"
      version = "#{@env}-#{hash}"
      puts "version: #{version}"
      dockerrun = "Dockerrun.aws.json"
      set_tag_to_deploy(dockerrun) if @tag
      unless ext?
        new_dockerrun = "#{version}-Dockerrun.aws.json"
        FileUtils.cp("Dockerrun.aws.json", new_dockerrun)
        new_dockerrun
      else
        zip = "#{version}.zip"
        clone_repo if repo?
        Archive::Zip.archive(zip, ['.ebextensions/', dockerrun])
        #FileUtils.rm_rf ".ebextensions/" if repo?
        zipped_version
      end
      `git checkout "Dockerrun.aws.json"` # reverts back to original Dockerrun.aws.json
    end

    def set_tag_to_deploy file
      docker = JSON.parse(IO.read(file))
      docker["Image"]["Name"].gsub!(/:(.*)$/, ":#{@tag}")
      IO.write(@version_label,JSON.pretty_generate(docker))
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
        repo = @ext.sub.(get_ext_branch)
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
      branch = @ext.match(/:.*(:.*)$/)[0]
    end

    def clone_repo
      if ext_branch?
        `git clone -b #{get_ext_branch} #{get_ext_repo}`
      else
        `git clone #{get_ext_repo}`
      end
    end

    def check_version_bucket
      name = "#{@app}-versions"
      bucket = @s3.buckets[name] # makes no request
      @s3.buckets.create(name) unless bucket.exists?
    end
  end
end
