ENV["VCR"] ? ENV["VCR"] : ENV["VCR"] = "1"
ENV["TEST"] = "1"
ENV["CODECLIMATE_REPO_TOKEN"] = ENV["CODECLIMATE_GANTREE_TOKEN"]

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require "pp"
require "vcr"
 
root = File.expand_path('../../', __FILE__)
require "#{root}/lib/gantree"

module Helpers
  def execute(cmd)
    puts "Running: #{cmd}" if ENV['DEBUG']
    out = `#{cmd}`
    raise "Stack Trance Found: \n #{out}" if out.include? "Error"
    puts out if ENV['DEBUG']
    out
  end
end

RSpec.configure do |c|
  c.include Helpers
  c.color = true
  c.tty = true
  c.formatter = :documentation
  c.after(:all) do
    FileUtils.rm_rf("Dockerrun.aws.json")
    FileUtils.rm_rf("*.zip")
  end
end

class Existence
  def self.exists?
    true
  end
end

class NonExistence
  def self.exists?
    false
  end
end
