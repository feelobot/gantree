require "spec_helper"
require "pry"

describe Gantree::Init do
  it "initializes the variables properly" do
    options = Thor::CoreExt::HashWithIndifferentAccess.new(
      "port" => "3000"
    )
    gi = Gantree::Init.new("bleacher/cauldron:master", options)

    expect(gi.image).to eq("bleacher/cauldron:master")
    expect(gi.options.port).to eq("3000")
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

