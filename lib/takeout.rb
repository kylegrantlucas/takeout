require 'takeout/version'
require 'takeout/endpoint_failure_error'
Dir["./takeout-ruby2.1.0/*.rb"].each {|file| require file } if RUBY_VERSION >= '2.1.0'
Dir["./takeout-ruby2.0.0/*.rb"].each {|file| require file } if RUBY_VERSION <= '2.0.0'

module Takeout
end
