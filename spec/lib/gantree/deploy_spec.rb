require "spec_helper"

describe Gantree::Deploy do
  before(:all) do
    ENV["AWS_ACCESS_KEY_ID"] = "FAKE_AWS_ACCESS_KEY"
    ENV["AWS_SECRET_ACCESS_KEY"] = "FAKE_AWS_SECRET_ACCESS_KEY"
    @stack_name = "knarr-stag-s1"
    @env = "stag-knarr-app-s1"
    @owner = "bleacher"
    @repo = "cauldron"
    @tag =  "master"
    @user = "feelobot"
  end

  it "returns branch name of repo url" do
    options = { ext: "git@github.com:br/.ebextensions:basic" }
    deploy = Gantree::Deploy.new(@env, options)
    expect(deploy.send(:get_ext_branch)).to eq("basic")
  end

  it "returns just the repo url" do
    options = { ext: "git@github.com:br/.ebextensions:basic" }
    deploy = Gantree::Deploy.new(@env, options)
    expect(deploy.send(:get_ext_repo)).to eq("git@github.com:br/.ebextensions")
  end

  it "sets app roles if enabled" do
    options = { autodetect_app_role: true }
    deploy = Gantree::Deploy.new("stag-knarr-listener-s1", options)
    expect(deploy.send(:autodetect_app_role, "stag-knarr-listener-s1")).to eq([ { :option_name=>"ROLE", :value=>"listener", :namespace=>"aws:elasticbeanstalk:application:environment" } ])
  end

  it "AWS gets the correct keys" do
    gd = Gantree::Deploy.new(
      "image_name",
      env: "cauldron-stag-s1"
    )
    expect(AWS).to receive(:config).with(
      access_key_id: "FAKE_AWS_ACCESS_KEY",
      secret_access_key: "FAKE_AWS_SECRET_ACCESS_KEY"
    )
    gd.set_aws_keys
  end

  it "the image path is dynamic" do
    options = { image_path: "quay.io/bleacherreport/cms" }
    deploy = Gantree::Deploy.new(@env, options)
    image_path = deploy.instance_variable_get("@options")[:image_path]
    expect(image_path).to eq("quay.io/bleacherreport/cms")
  end

  it "raises an error when no aws keys in ENV" do
    ENV['AWS_ACCESS_KEY_ID'] = nil
    ENV['AWS_SECRET_ACCESS_KEY'] = nil
    expect { gd = Gantree::Deploy.new(
      "image_name",
      env: "cauldron-stag-s1"
    )}.to raise_error(RuntimeError)
  end
end

def dockerrun
  '
  {
    "AWSEBDockerrunVersion": "1",
    "Image": {
      "Name": "bleacher/cms",
      "Update": true
    },
    "Logging": "/var/log/nginx",
    "Ports": [
      {
        "ContainerPort": "300"
      }
    ]
  }
  '
end
