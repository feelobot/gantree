require "spec_helper"
require "pry"

describe Gantree::Delete do
  before(:all) do
    AWS.stub!
    ENV['AWS_ACCESS_KEY_ID'] = 'FAKE_AWS_ACCESS_KEY'
    ENV['AWS_SECRET_ACCESS_KEY'] = 'FAKE_AWS_SECRET_ACCESS_KEY'
    @stack_name = "knarr-stag-s1"
  end

  it "prompts for confirmation"
  it "prompt requires 'y' to delete"
  it "prompt is canceled on any other input"
  let(:delete) { Gantree::Delete.new(@stack_name,{:force => true})}
  it "prompt can be overrided with --force" do
    expect { delete.run}.to output("Deleting stack from aws\n").to_stdout
  end

end