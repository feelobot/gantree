$:.unshift(File.expand_path("../", __FILE__))
require "gantree/version"
require "gantree/deploy"
require "gantree/init"

module Gantree
  autoload :CLI, 'gantree/cli'
end