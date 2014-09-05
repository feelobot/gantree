module Gantree
  class Deploy

    def initialize app,options
      @options = options
      AWS.config(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
      @env = app
      @app =@env.match(/^*\-(.*\-).*\-/)[1][0..-2]
      @version_label = set_version_label
      @eb = AWS::ElasticBeanstalk::Client.new
      @s3 = AWS::S3.new
      @tag = options.tag
    end

    def run
      puts "Deploying #{@app}"
      upload_to_s3
      create_version
      update_application
    end

    private

    def upload_to_s3
      
      filename = @version_label
      FileUtils.cp("Dockerrun.aws.json", filename)
      set_tag_to_deploy if @tag
      key = File.basename(filename)
      begin
        puts ENV['AWS_ACCESS_KEY_ID']
        @s3.buckets["#{@app}-versions"].objects[key].write(:file => filename)
      rescue AWS::S3::Errors::NoSuchBucket
        bucket = @s3.buckets.create("#{@app}-versions")
        retry
      rescue AWS::S3::Errors::AccessDenied
        puts "Your key is not configured for s3 access, please let your operations team know"
        exit
      end
      FileUtils.rm(filename)
    end

    def create_version
      begin
        @eb.create_application_version({
          :application_name => @app,
          :version_label => @version_label,
          :source_bundle => {
            :s3_bucket => "#{@app}-versions",
            :s3_key => @version_label
          }
        })
      rescue AWS::ElasticBeanstalk::Errors::InvalidParameterValue
        puts "Version already exists, recreating..."
        @eb.delete_application_version({
          :application_name => @app,
          :version_label => @version_label,
          :delete_source_bundle => true
        })
        retry
      end
    end

    def update_application
      begin
        @eb.update_environment({
          :environment_name => @env,
          :version_label => @version_label
        })
      rescue AWS::ElasticBeanstalk::Errors::InvalidParameterValue
        puts "#{@env} doesn't exist"
      end
    end

    def set_version_label
      branch = `git branch`
      branch = branch[2..-1]
      hash = `git rev-parse --verify --short #{branch}`.strip
      "#{@env}-#{hash}-Dockerrun.aws.json"
    end

    def set_tag_to_deploy
      docker =JSON.parse(IO.read("Dockerrun.aws.json"))
      docker["Image"]["Name"].gsub!(/:(.*)$/, ":#{@tag}")
      IO.write(@version_label,JSON.pretty_generate(docker))
    end
  end
end
