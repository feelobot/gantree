require "spec_helper"

describe Gantree::DeployVersion do
  before(:all) do
  end

  after(:all) do
    FileUtils.rm_f(Dir.glob("spec/fixtures/project/*.zip"))
  end

  it "should create package version" do
    @options = {
      :ext => "git@github.com:br/.ebextensions.git", 
      :tag => "br-develop_mkemnitz-30b9bf6", 
      :image_path => "bleacher/carburetor",
      :project_root => "spec/fixtures/project/"
    }
    @env = "stag-carburetor-app-s1"
    @version = Gantree::DeployVersion.new(@options, @env)
    packaged_version = @version.run
    expect(File.exist?(packaged_version)).to be true
  end

  it "should add auth info" do
    @options = {
      :ext => "git@github.com:br/.ebextensions.git", 
      :tag => "br-develop_mkemnitz-30b9bf6", 
      :image_path => "bleacher/carburetor",
      :project_root => "spec/fixtures/project/",
      :auth => "br-eb-versions/brops.dockercfg"
    }
    @env = "stag-carburetor-app-s1"
    @version = Gantree::DeployVersion.new(@options, @env)
    @version.set_auth
    data = JSON.parse(IO.read("/tmp/#{@version.dockerrun_file}"))
    expect(data["Authentication"]["Bucket"]).to eq "br-eb-versions"
    expect(data["Authentication"]["Key"]).to eq "brops.dockercfg"
  end

end