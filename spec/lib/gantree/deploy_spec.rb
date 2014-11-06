require "spec_helper"
require "pry"

describe Gantree::Deploy do
  it "raises an error when no aws keys in ENV" do
    ENV['AWS_ACCESS_KEY_ID'] = nil
    ENV['AWS_SECRET_ACCESS_KEY'] = nil
    expect{gd = Gantree::Deploy.new(
      "image_name",
       :env => "cauldron-stag-s1"
    )}.to raise_error(RuntimeError)
  end

  it "AWS gets the correct keys" do
    ENV['AWS_ACCESS_KEY_ID'] = '123453244'
    ENV['AWS_SECRET_ACCESS_KEY'] = '6789042335'
    gd = Gantree::Deploy.new(
      "image_name",
       :env => "cauldron-stag-s1"
    )
    expect(AWS).to receive(:config).with(
        :access_key_id => '123453244',
        :secret_access_key => '6789042335' 
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
end

