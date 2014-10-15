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
      options = { ext: "git@github.com:br/.ebextensions:feature" }
      deploy = Gantree::Deploy.new(@env,options)
      expect(deploy.instance_eval { get_ext_branch }).to eq "feature"
    end
  end
  
  describe ".get_ext_repo" do 
    it "returns just the repo url" do 
      options = { ext: "git@github.com:br/.ebextensions:feature" }
      deploy = Gantree::Deploy.new(@env,options)
      puts deploy.instance_eval { get_ext_repo } 
    end
  end 
end
