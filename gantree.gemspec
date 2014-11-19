# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gantree/version'

Gem::Specification.new do |spec|
  spec.name          = "gantree"
  spec.version       = Gantree::VERSION
  spec.authors       = ["Felix"]
  spec.email         = ["felix.a.rod@gmail.com"]
  spec.description   = "cli tool for automating docker deploys to elastic beanstalk"
  spec.summary       = "This tool is intended to help you setup a Dockerrun.aws.json which allows you to deploy a prebuilt image of your application to Elastic Beanstalk. This also allows you to do versioned deploys to your Elastic Beanstalk application and create an archive of every versioned Dockerrun.aws.json in amazons s3 bucket service."
  spec.homepage      = "https://github.com/feelobot/gantree"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  spec.add_dependency "aws-sdk-v1", "~>1.55.0"
  spec.add_dependency "hashie"
  spec.add_dependency "colorize"
  spec.add_dependency "rubyzip"
  spec.add_dependency "cloudformation-ruby-dsl","0.4.6"
  spec.add_dependency "archive-zip","~>0.7.0"
  spec.add_dependency "json"
  spec.add_dependency "slackr","0.0.6"
  spec.add_dependency "highline"
  spec.add_dependency "pry"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "vcr"
end

