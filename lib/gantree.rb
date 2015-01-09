$:.unshift(File.expand_path("../", __FILE__))
require "gantree/base"
require "gantree/version"
require "gantree/deploy"
require "gantree/deploy_applications"
require "gantree/deploy_version"
require "gantree/init"
require "gantree/delete"
require "gantree/update"
require "gantree/create"
require "gantree/app"
require "gantree/docker"

module Gantree
  autoload :CLI, 'gantree/cli'
end

