require "spec_helper"
require "pry"

describe Gantree::Init do
  before(:all) do
    ENV['AWS_ACCESS_KEY_ID'] = '123453244'
    ENV['AWS_SECRET_ACCESS_KEY'] = '6789042335'
    ENV["HOME"] = "/Users/gantree_user"

    @options = Thor::CoreExt::HashWithIndifferentAccess.new(
      "port" => "3000",
      "user" => "gantree_user"
    )
  end

  it "initializes the variables properly" do
   gi = Gantree::Init.new("bleacher/cauldron:master", @options)

    expect(gi.image).to eq("bleacher/cauldron:master")
    expect(gi.options.port).to eq("3000")
  end

  it "AWS gets the correct keys" do
    gi = Gantree::Init.new("image_name", {})
    expect(AWS).to receive(:config).with(
        :access_key_id => '123453244',
        :secret_access_key => '6789042335'
    )
    gi.set_aws_keys
  end

  it "generates a dockerrun object" do
    gi = Gantree::Init.new("bleacher/cauldron:master", @options)

    dro = gi.send(:dockerrun_object)
    expect(dro).to eq(
      :AWSEBDockerrunVersion=>"1",
      :Image=>{:Name=>"bleacher/cauldron:master", :Update=>true},
      :Logging=>"/var/log/nginx",
      :Ports=>[{:ContainerPort=>"3000"}],
      "Authentication"=>{:Bucket=>"docker-cfgs", :Key=>"gantree_user.dockercfg"}
    )
  end

  it "creates docker config folder" do
    gi = Gantree::Init.new("bleacher/cauldron:master", @options)
    AWS::S3::BucketCollection.any_instance.stub(:create).with("docker-cfgs") {"OK"}

    expect(gi.send(:create_docker_config_folder)).to eq("OK")
  end

  it "uploads docker config to s3" do
    gi = Gantree::Init.new("bleacher/cauldron:master", @options)

    Gantree::Init.any_instance.stub(:dockercfg_file_exist?) { true }
    FileUtils.stub(:cp).with(
      "/Users/gantree_user/.dockercfg", 
      "/Users/gantree_user/gantree_user.dockercfg"
    ) {"OK"}
    AWS::S3::S3Object.any_instance.stub(:write).with(
      :file => "/Users/gantree_user/gantree_user.dockercfg"
    ) {"OK"}

    expect(gi.send(:upload_docker_config)).to eq("OK")
  end
end

