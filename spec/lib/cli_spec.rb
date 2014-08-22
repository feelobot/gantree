require 'spec_helper'

# to run specs with what's remembered from vcr
#   $ rake
# 
# to run specs with new fresh data from aws api calls
#   $ rake clean:vcr ; time rake
describe Gantree::CLI do
  before(:all) do
    @args = "--noop"
  end

  describe "gantree" do
    it "should create base" do
      out = execute("bin/gantree base #{@args}")
      out.should include("Creating base gantree!")
    end
  end
end