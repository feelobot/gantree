require "spec_helper"

describe Gantree::ReleaseNotes do
  before(:all) do
    @wiki = "https://github.com/br/dev.wiki.git"
    @env_name = "stag-rails-app-s1"
    @packaged_version = "br-master-d961c96-06-17-2015-23-33-25.zip"
    @rn = Gantree::ReleaseNotes.new(@wiki, @env_name, @packaged_version)
    @rn.beanstalk = Aws::ElasticBeanstalk::Client.new(stub_responses: true)
  end

  def mock_environment
    double(
      version_label: "br-master-fb3e1cd-23.zip",
      application_name: "rails"
    )
  end
  
  it "can retrieve the latest deployed master tag" do
    allow(@rn).to receive(:environment).and_return(mock_environment)
    expect(@rn.previous_tag).to include "br-master"
  end

  it "can retrieve the latest deployed sha from the master tag" do
    allow(@rn).to receive(:environment).and_return(mock_environment)
    expect(@rn.previous_sha).to eq "fb3e1cd"
  end

  it "can retrieve the current sha" do
    expect(@rn.current_sha).to eq "d961c96"
  end

  it "should generate notes" do
    allow(@rn).to receive(:environment).and_return(mock_environment)
    allow(@rn).to receive(:git_log).and_return(git_log_mock)
    notes = @rn.notes
    puts notes if ENV['DEBUG']
    expect(notes).to include(@env_name)
    expect(notes).to include(@rn.pacific_time)
    expect(notes).to include("compare")
    expect(notes).to include("test up controller")
  end

  it "should grab commit messages" do
    allow(@rn).to receive(:git_log).and_return(git_log_mock)
    commits = @rn.commits
    p commits if ENV['DEBUG']
    expect(commits).to be_a(Array)
    expect(commits).to include("commit 1")
    expect(commits).to include("commit 2")
  end
end