# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :bundler do
  require 'guard/bundler'
  require 'guard/bundler/verify'
  helper = Guard::Bundler::Verify.new

  files = ['Gemfile']
  files += Dir['*.gemspec'] if files.any? { |f| helper.uses_gemspec?(f) }

  # Assume files are symlinked from somewhere
  files.each { |file| watch(helper.real_path(file)) }
end

# Note: The cmd option is now required due to the increasing number of ways
#       rspec may be run, below are examples of the most common uses.
#  * bundler: 'bundle exec rspec'
#  * bundler binstubs: 'bin/rspec'
#  * spring: 'bin/rspec' (This will use spring if running and you have
#                          installed the spring binstubs per the docs)
#  * zeus: 'zeus rspec' (requires the server to be started separately)
#  * 'just' rspec: 'rspec'

guard :rspec, cmd: "bundle exec rspec" do
  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)

  # Feel free to open issues for suggestions and improvements

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  watch(%r{^lib/takeout/(.+)\.rb$}) { |m| puts m; "spec/#{m.last}_spec.rb" }
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/lib/#{m.last}_spec.rb" }
end

guard 'rake', task: 'build', run_on_all: true, run_on_start: true do
  watch(%r{^lib/takeout/client.rb})
end

guard 'rake', task: 'install', run_on_all: true, run_on_start: true do
  watch(%r{^lib/takeout/client.rb})
end
