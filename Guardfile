guard :rspec, cmd: 'bundle exec rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})      { "spec/cli_spec.rb" }
  watch(%r{^lib/gantree/(.+)\.rb$})  { "spec/cli_spec.rb" }
  watch('spec/spec_helper.rb')   { "spec/gantree_spec.rb" }
  watch(%r{^lib/gantree/(.+)\.rb$})   { |m| "spec/lib/gantree/#{m[1]}_spec.rb" }
end

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end