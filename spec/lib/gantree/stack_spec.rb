require "spec_helper"
require "pry"

describe Gantree::Stack do
  it "parses the env from env options" do
    gs = Gantree::Stack.new(
      "stag-linguist-app-s1",
       :env => "linguist-stag-s1"
    )
    
    expect(gs.env).to eq("linguist-stag-s1")
  end

  it "parses the env from stack_name" do
    gs = Gantree::Stack.new(
      "stag-linguist-app-s1",
      {}
    )

    expect(gs.env).to eq("linguist-stag-s1")
  end
end

