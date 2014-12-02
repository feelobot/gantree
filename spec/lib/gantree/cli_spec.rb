require 'spec_helper'

# to run specs with what's remembered from vcr
#   $ rake
# 
# to run specs with new fresh data from aws api calls
#   $ rake clean:vcr ; time rake
describe Gantree::CLI do
  before(:all) do

    @app = "stag-knarr-app-s1"
    @env = "knarr-stag-s1"
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
      out = execute("bin/gantree init -u #{@user} -b my_bucket #{@owner}/#{@repo}:#{@tag} --dry-run")
      expect(out).to include "bucket: my_bucket"
    end
  end

  describe "deploy" do
    it "should deploy images" do
      execute("bin/gantree init #{@owner}/#{@repo}:#{@tag} --dry-run")
      out = execute("bin/gantree deploy #{@env} --dry-run --silent")
      expect(out).to include("Found Environment: knarr-stag-s1")
      expect(out).to include("dry_run: dry_run")
      expect(out).to include("silent: silent")
    end

    it "should deploy images with remote extensions" do
      out = execute("bin/gantree deploy #{@app} -x 'git@github.com:br/.ebextensions' --dry-run --silent")
      expect(out).to include("Found Environment: stag-knarr-app-s1")
      expect(out).to include("ext: git@github.com:br/.ebextensions")
      expect(out).to include("dry_run: dry_run")
      expect(out).to include("silent: silent")
    end

    it "should deploy images with remote extensions on a branch" do
      out = execute("bin/gantree deploy #{@env} -x 'git@github.com:br/.ebextensions:basic' --dry-run --silent")
      expect(out).to include("Found Environment: knarr-stag-s1")
      expect(out).to include("ext: git@github.com:br/.ebextensions:basic")
      expect(out).to include("dry_run: dry_run")
      expect(out).to include("silent: silent")
    end

    it "should notify slack of deploys" do 
      out = execute("bin/gantree deploy #{@env} --dry-run")
      expect(out).to include("Found Environment: knarr-stag-s1")
    end
  end

  describe "create" do
    it "should create clusters" do
      out = execute("bin/gantree create #{@env} --dry-run")
      expect(out).to include "instance_size: m3.medium"
      expect(out).to include "stack_name: knarr-stag-s1"
      expect(out).to include "cfn_bucket: br-templates"
    end

    it "should create clusters with any docker version" do
      out = execute("bin/gantree create #{@env} --dry-run --docker-version '64bit Amazon Linux 2014.03 v1.0.1 running Docker 1.0.0'")
      expect(out).to include "docker_version: 64bit Amazon Linux 2014.03 v1.0.1 running Docker 1.0.0"
    end

    it "should create clusters with databases" do
      out = execute("bin/gantree create #{@env} --dry-run --rds pg")
      expect(out).to include "rds: pg"
      expect(out).to include "rds_enabled: true"
    end

    it "should create dupliacte clusters from local cfn" do 
      out = execute("bin/gantree create knarr-stag-s2 --dupe #{@env} --dry-run")
      expect(out).to include "dupe: knarr-stag-s1"
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
end

