$:.unshift(File.expand_path("../", __FILE__))
require "gantree/base"
require "gantree/version"
require "gantree/deploy"
require "gantree/init"
require "gantree/cfn"

module Gantree
  autoload :CLI, 'gantree/cli'
end
