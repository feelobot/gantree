require "spec_helper"
require "pry"

describe Gantree::Init do
  before(:all) do
    ENV['AWS_ACCESS_KEY_ID'] = '123453244'
    ENV['AWS_SECRET_ACCESS_KEY'] = '6789042335'
  end

  it "initializes the variables properly" do
    options = Thor::CoreExt::HashWithIndifferentAccess.new(
      "port" => "3000"
    )
    gi = Gantree::Init.new("bleacher/cauldron:master", options)

    expect(gi.image).to eq("bleacher/cauldron:master")
    expect(gi.options.port).to eq("3000")
  end

  it "AWS gets the correct keys" do
    ENV['AWS_ACCESS_KEY_ID'] = '12345'
    ENV['AWS_SECRET_ACCESS_KEY'] = '67890'
    gi = Gantree::Init.new("image_name", {})
    expect(AWS).to receive(:config).with(
        :access_key_id => '12345',
        :secret_access_key => '67890' 
    )
    gi.set_aws_keys
  end

  it "generates a dockerrun object" do
    options = Thor::CoreExt::HashWithIndifferentAccess.new(
      "port" => "3000",
      "user" => "gantree_user"
    )
    gi = Gantree::Init.new("bleacher/cauldron:master", options)

    dro = gi.send(:dockerrun_object)
    expect(dro).to eq(
      :AWSEBDockerrunVersion=>"1",
      :Image=>{:Name=>"bleacher/cauldron:master", :Update=>true},
      :Logging=>"/var/log/nginx",
      :Ports=>[{:ContainerPort=>"3000"}],
      "Authentication"=>{:Bucket=>"docker-cfgs", :Key=>"gantree_user.dockercfg"}
    )
  end
end

