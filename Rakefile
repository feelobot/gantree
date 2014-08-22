# require "bundler/gem_tasks"
require "rspec/core/rake_task"

task :default => :spec

RSpec::Core::RakeTask.new

namespace :spec do
  desc "Run acceptance specs, forces AWS calls by cleaning vcr fixtures first,  ~/.br/aws.yml needs to be set up"
  task :acceptance => %w[clean:vcr] do
    ENV['LIVE'] = "1"
    Rake::Task["spec"].invoke
  end
end

task :clean => %w[clean:vcr]
namespace :clean do
  desc "clean vcr_cassettes fixtures"
  task :vcr do
    FileUtils.rm_rf('spec/fixtures/vcr_cassettes')
  end
end
