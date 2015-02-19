require 'spec_helper'

# to run specs with what's remembered from vcr
#   $ rake
# 
# to run specs with new fresh data from aws api calls
#   $ rake clean:vcr ; time rake
describe Gantree::CLI do
  before(:all) do

    @app = "stag-carburetor-app-s2"
    @env = "carburetor"
    @owner = "bleacher"
    @repo = "cauldron"
    @tag =  "master"
    @user = "feelobot"
  end 

  describe "init" do
    it "should create a new dockerrun for a private repo" do 
      out = execute("bin/gantree init -u #{@user} #{@owner}/#{@repo}:#{@tag} --dry-run")
      expect(out).to include "initialize image"
      expect(File.exist?("Dockerrun.aws.json")).to be true
      expect(IO.read("Dockerrun.aws.json").include? @user)
    end

    it "should create a new dockerrun for a public repo" do 
      out = execute("bin/gantree init #{@owner}/#{@repo}:#{@tag} --dry-run")
      expect(out).to include "initialize image"
      expect(File.exist?("Dockerrun.aws.json")).to be true
    end

    it "specifies the bucket" do
      out = execute("bin/gantree init -u #{@user} -b docker-cfgs #{@owner}/#{@repo}:#{@tag} --dry-run")
      expect(out).to include "bucket: docker-cfgs"
    end
  end

  describe "deploy" do
    it "should deploy images" do
      execute("bin/gantree init #{@owner}/#{@repo}:#{@tag} --dry-run")
      out = execute("bin/gantree deploy #{@env} --dry-run  --eb-bucket br-eb-versions --silent")
      expect(out).to include("Found Application: #{@env}")
      expect(out).to include("silent: silent")
    end

    it "should deploy images with remote extensions" do
      out = execute("bin/gantree deploy #{@app} -x 'git@github.com:br/.ebextensions' --eb-bucket br-eb-versions --dry-run --silent")
      expect(out).to include("Found Environment: #{@app}")
      expect(out).to include(".ebextensions")
      expect(out).to include("silent: silent")
    end

    it "should deploy images with remote extensions on a branch" do
      out = execute("bin/gantree deploy #{@env} -x 'git@github.com:br/.ebextensions:basic' --eb-bucket br_eb_versions --dry-run --silent")
      expect(out).to include("Found Application: #{@env}")
      expect(out).to include(".ebextensions:basic")
      expect(out).to include("silent: silent")
    end

    it "should notify slack of deploys" do 
      out = execute("bin/gantree deploy #{@env} --eb-bucket br_eb_versions  --dry-run")
      expect(out).to include("Found Application: #{@env}")
    end
  end
=begin
  describe "create" do
    it "should create clusters" do
      out = execute("bin/gantree create #{@env} --dry-run --cfn-bucket templates")
      expect(out).to include "instance_size: m3.medium"
      expect(out).to include "stack_name: #{@env}"
      expect(out).to include "cfn_bucket: templates"
    end

    it "should create clusters with any docker version" do
      out = execute("bin/gantree create #{@env} --dry-run --solution '64bit Amazon Linux 2014.03 v1.0.1 running Docker 1.0.0' --cfn-bucket template")
      expect(out).to include "solution: 64bit Amazon Linux 2014.03 v1.0.1 running Docker 1.0.0"
    end

    it "should create clusters with databases" do
      out = execute("bin/gantree create #{@env} --dry-run --rds pg --cfn-bucket template")
      expect(out).to include "rds: pg"
      expect(out).to include "rds_enabled: true"
    end

    it "should create dupliacte clusters from local cfn" do 
      out = execute("bin/gantree create #{@new_env} --dupe #{@env} --dry-run --cfn-bucket template")
      expect(out).to include "dupe: #{@env}"
    end
  end

  describe "update" do
    it "should update existing clusters" do
      out = execute("bin/gantree update #{@env} --dry-run --cfn-bucket template")
      expect(out).to include "Updating"
    end
  end

  describe "delete" do
    it "should update existing clusters" do
      out = execute("bin/gantree delete #{@env} --dry-run --force")
      expect(out).to include "Deleting"
    end
  end
=end
  describe "#version" do
    it "should output gantree version" do
      out = execute("bin/gantree version")
      expect(out).to match /\d\.\d\.\d/
    end

    it "should output gantree version using alias" do
      out = execute("bin/gantree -v")
      expect(out).to match /\d\.\d\.\d/
    end
  end
end

