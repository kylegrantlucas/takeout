require 'takeout/version'
require 'takeout/endpoint_failure_error'
require 'takeout-ruby2.1.0/client' if RUBY_VERSION >= '2.1.0'
require 'takeout-ruby2.0.0/client' if RUBY_VERSION <= '2.0.0'

module Takeout
end
