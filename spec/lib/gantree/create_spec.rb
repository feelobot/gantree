require "spec_helper"
require "pry"

describe Gantree::Update do
  before(:all) do
    ENV['AWS_ACCESS_KEY_ID'] = 'FAKE_AWS_ACCESS_KEY'
    ENV['AWS_SECRET_ACCESS_KEY'] = 'FAKE_AWS_SECRET_ACCESS_KEY'

    @stack_name = "knarr-stag-s1"
    @env = "stag-knarr-app-s1"
    @owner = "bleacher"
    @repo = "cauldron"
    @tag =  "master"
    @user = "feelobot"
  end

  it "performs a cloudformation stack update"
  it "can add an application role to the stack template"
  it "can update to a specific solution stack"
  it "can update to the latest solution stack automatically"
end