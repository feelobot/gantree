require "spec_helper"
require "pry"

describe Gantree::Deploy do
  before(:all) do
    ENV['AWS_ACCESS_KEY_ID'] = 'FAKE_AWS_ACCESS_KEY'
    ENV['AWS_SECRET_ACCESS_KEY'] = 'FAKE_AWS_SECRET_ACCESS_KEY'

    @env = "stag-knarr-app-s1"
    @owner = "bleacher"
    @repo = "cauldron"
    @tag =  "master"
    @user = "feelobot"
  end

  it "returns branch name of repo url" do
    options = { ext: "git@github.com:br/.ebextensions:basic" }
    deploy = Gantree::Deploy.new(@env, options)
    expect(deploy.instance_eval { get_ext_branch }).to eq "basic"
  end

  it "returns just the repo url" do 
    options = { ext: "git@github.com:br/.ebextensions:basic" }
    deploy = Gantree::Deploy.new(@env,options)
    expect(deploy.instance_eval { get_ext_repo }).to eq "git@github.com:br/.ebextensions"
  end

  it "sets app roles if enabled" do
    options = { autodetect_app_role: true}
    deploy = Gantree::Deploy.new("stag-knarr-listener-s1",options)
    puts deploy.instance_eval { autodetect_app_role }
  end

  it "AWS gets the correct keys" do
    gd = Gantree::Deploy.new(
      "image_name",
       :env => "cauldron-stag-s1"
    )
    expect(AWS).to receive(:config).with(
        :access_key_id => 'FAKE_AWS_ACCESS_KEY',
        :secret_access_key => 'FAKE_AWS_SECRET_ACCESS_KEY' 
    )
    gd.set_aws_keys
  end

  it "parses env option" do
    gd = Gantree::Deploy.new(
      "stag-cauldron-app-s1",
       :env => "cauldron-stag-s1"
    )
    expect(gd.app).to eq("cauldron-stag-s1")
    expect(gd.env).to eq("stag-cauldron-app-s1")
  end

  it "parses default env" do
    gd = Gantree::Deploy.new(
      "stag-cauldron-app-s1",
      {}
    )
    expect(gd.app).to eq("cauldron-stag-s1")
    expect(gd.env).to eq("stag-cauldron-app-s1")
  end

  it "raises an error when no aws keys in ENV" do
    ENV['AWS_ACCESS_KEY_ID'] = nil
    ENV['AWS_SECRET_ACCESS_KEY'] = nil
    expect{gd = Gantree::Deploy.new(
      "image_name",
       :env => "cauldron-stag-s1"
    )}.to raise_error(RuntimeError)
  end
end

