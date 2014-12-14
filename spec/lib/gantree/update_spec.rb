require "spec_helper"
require "pry"

describe Gantree::Update do
  before(:all) do
    AWS.stub!
    ENV['AWS_ACCESS_KEY_ID'] = 'FAKE_AWS_ACCESS_KEY'
    ENV['AWS_SECRET_ACCESS_KEY'] = 'FAKE_AWS_SECRET_ACCESS_KEY'

    @stack_name = "cms-stag-s2"
    @env = "stag-knarr-app-s1"
    @owner = "bleacher"
    @repo = "cauldron"
    @tag =  "master"
    @user = "feelobot"
  end

  let(:update) { Gantree::Update.new(@stack_name,{:dry_run => true}).run}
  it "performs a cloudformation stack update" do
    expect { update }.to output("Updating stack from local cfn repo\n").to_stdout
  end
  
  it "can update to a specific solution stack"
  it "can update to the latest solution stack automatically"

  describe "add_role" do
    let(:update) { Gantree::Update.new(@stack_name,{:role => "worker", :dry_run => true})}
    it "can add an worker role to the stack template" do
      expect{ update.add_role "worker"}.to output("\e[0;31;49mRole already exists\e[0m\n").to_stdout
      #puts update.send(:add_role, "worker")   
    end
  end
end