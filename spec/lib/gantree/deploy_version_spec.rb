require "spec_helper"

describe Gantree::DeployVersion do
  before(:all) do
    @options = {
      :ext => "git@github.com:br/.ebextensions.git", 
      # :ext_role => "https://github.com/br/ext_role", 
      :tag => "br-develop_mkemnitz-30b9bf6", 
      :image_path => "bleacher/carburetor",
      :project_root => "spec/fixtures/project/"
    }
    @env = "stag-carburetor-app-s1"
    @version = Gantree::DeployVersion.new(@options, @env)
  end

  it "true" do
    packaged_version = @version.run
    expect(File.exist?(packaged_version)).to be true
  end

end
