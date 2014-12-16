require "spec_helper"
require "pry"

describe Gantree::Update do
  before(:all) do
    AWS.stub!
    ENV['AWS_ACCESS_KEY_ID'] = 'FAKE_AWS_ACCESS_KEY'
    ENV['AWS_SECRET_ACCESS_KEY'] = 'FAKE_AWS_SECRET_ACCESS_KEY'

    @stack_name = "cms-stag-s2"
    @env = "stag-cms-app-s1"
    @owner = "bleacher"
    @repo = "cauldron"
    @tag =  "master"
    @user = "feelobot"
  end

  let(:update) { Gantree::Update.new(@stack_name,{:dry_run => true}).run}
  it "performs a cloudformation stack update" do
    expect { update }.to output("Updating stack from local cfn repo\n").to_stdout
  end

  describe "change_solution_stack" do
    let!(:update) { Gantree::Update.new(@stack_name,{:dry_run => true,:solution => "64bit Amazon Linux 2014.09 v1.0.10 running Docker 1.3.2"})}
    it "can update to a specific solution stack using --role 'solution name'" do
      expect { update.change_solution_stack }.to output("\e[0;32;49mUpdated solution to 64bit Amazon Linux 2014.09 v1.0.10 running Docker 1.3.2\e[0m\n").to_stdout
    end
    let!(:update) { Gantree::Update.new(@stack_name,{:dry_run => true,:solution => "64bit Amazon Linux 2014.09 v1.0.10 running Docker 1.3.2"})}
    it "can update to the latest solution stack automatically using --role latest" do
      #expect { update.get_latest_docker_solution }.to output("asda").to_stdout
    end
  end

  describe "add_role" do
    let(:update) { Gantree::Update.new(@stack_name,{:role => "worker", :dry_run => true})}
    it "can add an worker role to the stack template with --role" do
      expect{ update.add_role "worker"}.to_not output("\e[0;31;49mRole already exists\e[0m\n").to_stdout 
    end
  end
end