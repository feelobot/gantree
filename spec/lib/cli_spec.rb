require 'spec_helper'

# to run specs with what's remembered from vcr
#   $ rake
# 
# to run specs with new fresh data from aws api calls
#   $ rake clean:vcr ; time rake
describe Gantree::CLI do
  before(:all) do
    @env = "stag-knarr-app-s1"
    @app = "knarr-stag-s1"
    @owner = "bleacher"
    @repo = "cauldron"
    @tag =  "master"
    @user = "feelobot"
  end 

  describe "init" do
    it "should create a new dockerrun for a private repo" do 
      out = execute("bin/gantree init -u #{@user} #{@owner}/#{@repo}:#{@tag}")
      expect(out).to include "initialize image"
      expect(File.exist?("Dockerrun.aws.json")).to be true
      expect(IO.read("Dockerrun.aws.json").include? @user)
    end

    it "should create a new dockerrun for a public repo" do 
      out = execute("bin/gantree init #{@owner}/#{@repo}:#{@tag}")
      expect(out).to include "initialize image"
      expect(File.exist?("Dockerrun.aws.json")).to be true
    end
  end

  describe "deploy" do
    it "should deploy images" do
      out = execute("bin/gantree deploy #{@env} --dry-run")
      expect(out).to include("Deploying")
    end
    it "should deploy images with remote extensions" do
      out = execute("bin/gantree deploy #{@env} -x 'git@github.com:br/.ebextensions' --dry-run")
      expect(out).to include("Deploying")
    end
    it "should deploy images with remote extensions on a branch" do
      out = execute("bin/gantree deploy #{@env} -x 'git@github.com:br/.ebextensions:basic' --dry-run")
      expect(out).to include("Deploying")
    end
  end

  describe "create" do
    it "should create clusters" do
      out = execute("bin/gantree create #{@env} --dry-run")
      beanstalk = JSON.parse(IO.read("cfn/#{@app}-beanstalk.cfn.json"))["Resources"]["ConfigurationTemplate"]["Properties"]["SolutionStackName"]
      expect(beanstalk).to include "Docker 1.2.0"
      expect(out).to include "Generating"
      expect_all_templates_created(out)
    end

    it "should create clusters with any docker version" do
      out = execute("bin/gantree create #{@env} --dry-run --docker-version '64bit Amazon Linux 2014.03 v1.0.1 running Docker 1.0.0'")
      beanstalk = JSON.parse(IO.read("cfn/#{@app}-beanstalk.cfn.json"))["Resources"]["ConfigurationTemplate"]["Properties"]["SolutionStackName"]
      expect(beanstalk).to include "Docker 1.0.0"
      expect_all_templates_created(out)
    end

    it "should create clusters with databases" do
      out = execute("bin/gantree create #{@env} --dry-run --rds pg")
      expect(out).to_not include "RDS is not enabled, no DB created"
    end

    it "should create dupliacte clusters from local cfn" do 
      out = execute("bin/gantree create stag-knarr-app-s2 --dupe #{@env} --dry-run")
      expect(out).to include "Duplicating"
    end
  end

  describe "update" do
    it "should update existing clusters" do
      out = execute("bin/gantree update #{@env} --dry-run")
      expect(out).to include "Updating"
    end
  end

  describe "delete" do
    it "should update existing clusters" do
      out = execute("bin/gantree delete #{@env} --dry-run --force")
      expect(out).to include "Deleting"
    end
  end

  def expect_all_templates_created(out)
    expect(out).to include "#{@app}-master.cfn.json"
    expect(out).to include "#{@app}-beanstalk.cfn.json"
    expect(out).to include "#{@app}-resources.cfn.json"
    end
end
