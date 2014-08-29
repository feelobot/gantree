require 'thor'
require 'aws-sdk'
require 'gantree/cli/help'

module Gantree

  class CLI < Thor
    AWS.config(
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCES_KEY'])

    class_option :verbose, :type => :boolean
    desc "deploy APP", "deploy specified APP"
    option :branch, :desc => 'branch to deploy'
    option :tag,    :desc => 'set image tag'
    def deploy(app)
      @env = app
      @app = app.match(/^*\-(.*\-).*\-/)[1][0..-2]
      @version_label = set_version_label
      @eb = AWS::ElasticBeanstalk::Client.new
      puts "Deploying #{app}"
      upload_to_s3(app + "-versions")
      create_version
      update_application
    end

    private

    def upload_to_s3 (dir)
      s3 = AWS::S3.new
      filename = @version_label
      FileUtils.cp("Dockerrun.aws.json", filename)
      key = File.basename(filename)
      s3.buckets[dir].objects[key].write(:file => filename)
      FileUtils.rm(filename)
    end

    def create_version
      begin
        @eb.create_application_version({
          :application_name => @app,
          :version_label => "#{@app}-#{@version_label}",
          :source_bundle => {
            :s3_bucket => "#{@app}-versions",
            :s3_key => @version_label
          }
        })
      rescue AWS::ElasticBeanstalk::Errors::InvalidParameterValue
        puts "Version not created, already exists"
      end
    end

    def update_application
      @eb.update_environment({
        :environment_name => @env,
        :version_label => "#{@app}-#{@version_label}"
      })

    end

    def set_version_label
      branch = `git branch`
      branch = branch[2..-1]
      hash = `git rev-parse --verify --short #{branch}`.strip
      "#{hash}-Dockerrun.aws.json"
    end
  end
end
