require 'spec_helper'
require_relative '../../lib/gantree/deploy'

describe "#Deploy" do
  before(:all) do
    @env = "stag-knarr-app-s1"
    @owner = "bleacher"
    @repo = "cauldron"
    @tag =  "master"
    @user = "feelobot"
  end 

  describe ".get_ext_branch" do
    it "returns branch name of repo url" do
      options = { ext: "git@github.com:br/.ebextensions:basic" }
      deploy = Gantree::Deploy.new(@env,options)
      expect(deploy.instance_eval { get_ext_branch }).to eq "basic"
    end
  end
  
  describe ".get_ext_repo" do 
    it "returns just the repo url" do 
      options = { ext: "git@github.com:br/.ebextensions:basic" }
      deploy = Gantree::Deploy.new(@env,options)
      expect(deploy.instance_eval { get_ext_repo }).to eq "git@github.com:br/.ebextensions"
    end
  end

  describe ".auto_detect_app_role" do
    it "sets app roles if enabled" do
      options = { autodetect_app_role: true}
      deploy = Gantree::Deploy.new("stag-knarr-listener-s1",options)
      puts deploy.instance_eval { autodetect_app_role }
    end
  end
end
