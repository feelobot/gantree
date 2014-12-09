require "spec_helper"
require "pry"

describe Gantree::Docker do
  before(:all) do
    ENV['AWS_ACCESS_KEY_ID'] = 'FAKE_AWS_ACCESS_KEY'
    ENV['AWS_SECRET_ACCESS_KEY'] = 'FAKE_AWS_SECRET_ACCESS_KEY'
  end

  it "requires an image_path option to be set"
  it "generates a unique tag for you"
  it "allows you to set your own tag to build"
  it "allows you to set your own tag to push"
  it "builds dockerfiles with tag"
  it "accepts image path parameter"
  it "pushes tag to dockerhub"

end

