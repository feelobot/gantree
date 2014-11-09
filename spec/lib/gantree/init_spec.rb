require "spec_helper"
require "pry"

describe Gantree::Init do
  before(:all) do
    ENV['AWS_ACCESS_KEY_ID'] = 'FAKE_AWS_ACCESS_KEY'
    ENV['AWS_SECRET_ACCESS_KEY'] = 'FAKE_AWS_SECRET_ACCESS_KEY'

    ENV["HOME"] = "/Users/gantree_user"

    @options = Thor::CoreExt::HashWithIndifferentAccess.new(
      "port" => "3000",
      "user" => "gantree_user",
      "bucket" => "bucket314159"
    )

    @s3_bucket = AWS::S3::Bucket.new("bucket314159")
  end

 it "initializes the variables properly" do
   gi = Gantree::Init.new("bleacher/cauldron:master", @options)

    expect(gi.image).to eq("bleacher/cauldron:master")
    expect(gi.options.port).to eq("3000")
  end

  it "AWS gets the correct keys" do
    gi = Gantree::Init.new("image_name", @options)
    expect(AWS).to receive(:config).with(
        :access_key_id => 'FAKE_AWS_ACCESS_KEY',
        :secret_access_key => 'FAKE_AWS_SECRET_ACCESS_KEY'
    )
    gi.set_aws_keys
  end

  it "uses default bucket_name" do
    options_no_bucket_name = Thor::CoreExt::HashWithIndifferentAccess.new(
      "port" => "3000",
      "user" => "gantree_user"
    )
    gi = Gantree::Init.new("image_name", options_no_bucket_name)
    expect(gi.bucket_name).to eq("gantree_user-docker-cfgs")

    options_no_bucket_name_or_user = Thor::CoreExt::HashWithIndifferentAccess.new(
      "port" => "3000"
    )
    gi2 = Gantree::Init.new("image_name", options_no_bucket_name_or_user)
    expect(gi2.bucket_name).to eq("docker-cfgs")
  end

  it "generates a dockerrun object" do
    gi = Gantree::Init.new("bleacher/cauldron:master", @options)

    dro = gi.send(:dockerrun_object)
    expect(dro).to eq(
      :AWSEBDockerrunVersion=>"1",
      :Image=>{:Name=>"bleacher/cauldron:master", :Update=>true},
      :Logging=>"/var/log/nginx",
      :Ports=>[{:ContainerPort=>"3000"}],
      "Authentication"=>{:Bucket=>"bucket314159", :Key=>"gantree_user.dockercfg"}
    )
  end

  it "creates docker config folder when s3 bucket already exists" do
    gi = Gantree::Init.new("bleacher/cauldron:master", @options)
    AWS::S3::BucketCollection.any_instance.stub(:[]).with(anything()) {Existence}
    AWS::S3::BucketCollection.stub(:create) {"OK"}

    expect(gi.send(:create_docker_config_s3_bucket)).to eq(nil)
  end

  it "creates docker config folder when s3 bucket doesnt not exist" do
    gi = Gantree::Init.new("bleacher/cauldron:master", @options)
    AWS::S3::BucketCollection.any_instance.stub(:[]).with(anything()) {NonExistence}
    AWS::S3::BucketCollection.any_instance.stub(:create).with(@options.bucket) {@s3_bucket}

    expect(gi.send(:create_docker_config_s3_bucket)).to eq(@s3_bucket)
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

