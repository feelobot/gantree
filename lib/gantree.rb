$:.unshift(File.expand_path("../", __FILE__))
require "gantree/base"
require "gantree/version"
require "gantree/deploy"
require "gantree/init"
require "gantree/stack"
require "gantree/app"
require "gantree/docker"

module Gantree
  autoload :CLI, "gantree/cli"
end
