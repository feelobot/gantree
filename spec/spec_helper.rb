# Running specs by default will use VCR.
# Can disable via: VCR=0 rake or clean out vcr fixtures via rake clean:vcr.
# Using a ENV VCR flag so that both ruby and cli specs always either use
# vcr or do not use vcr.  It's confusing to only have only ruby use vcr
# and cli specs not using vcr and vice versa.
ENV['VCR'] ? ENV['VCR'] : ENV['VCR'] = '1'
ENV['TEST'] = '1'
ENV['CODECLIMATE_REPO_TOKEN'] = ENV['CODECLIMATE_GANTREE_TOKEN']

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require "pp"
 
root = File.expand_path('../../', __FILE__)
require "#{root}/lib/gantree"

module Helpers
  def execute(cmd)
    puts "Running: #{cmd}" if ENV['DEBUG']
    out = `#{cmd}`
    puts out if ENV['DEBUG']
    out
  end
end

RSpec.configure do |c|
  c.include Helpers
  # Use color in STDOUT
  c.color = true

  # Use color not only in STDOUT but also in pagers and files
  c.tty = true

  # Use the specified formatter
  c.formatter = :documentation # :progress, :html, :textmate
  #c.around(:each) do |example|
  #  VCR.use_cassette(example.metadata[:full_description], :serialize_with => :json) do
  #    example.run
  #  end if ENV['VCR'] == '1'
  #end
end

#VCR.configure do |config|
#  config.ignore_hosts 'codeclimate.com'
#end if ENV['VCR'] == '1'
