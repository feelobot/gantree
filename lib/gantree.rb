$:.unshift(File.expand_path("../", __FILE__))
require "gantree/version"
require "gantree/deploy"
require "gantree/init"
require "thor/vcr" if ENV['VCR'] == '1'

module Gantree
  autoload :CLI, 'gantree/cli'
end