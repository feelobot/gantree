
require "spec_helper"
require "pry"

describe Gantree::ReleaseNotes do
  before(:all) do
    @app = "cms"
    @hash = "9ef330b"
    @wiki = "git@github.com:br/dev.wiki.git"
    @release_notes = Gantree::ReleaseNotes.new(@wiki,@app,@hash)
    @release_notes.instance_variable_set("@beanstalk", Aws::ElasticBeanstalk::Client.new(stub_responses: true))
  end
  
  it "can retrieve the latest deployed master tag" do
    expect(@release_notes.send(:get_latest_tag)).to include "br-master"
  end
  
  it "can get the last deployed hash" do
    expect(@release_notes.send(:last_deployed_hash).length).to eq 7
  end
  
  it "can show release notes" do
     expect(@release_notes.send(:release_notes)).to include "github.com/br/#{@app}/compare/#{@release_notes.send(:last_deployed_hash)}..."
  end
end
