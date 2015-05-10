# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'takeout/version'

Gem::Specification.new do |spec|
  spec.name          = "takeout"
  spec.version       = Takeout::VERSION
  spec.authors       = ["Kyle Lucas"]
  spec.email         = ["kglucas93@gmail.com"]
  spec.summary       = %q{A simple ruby library to autogenerate api clients.}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"
  spec.required_ruby_version = '>= 1.8.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "oj"
  spec.add_runtime_dependency "curb"
  spec.add_runtime_dependency "liquid"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sinatra"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "guard", "2.12.5"
  spec.add_development_dependency "guard-rspec", '4.5.0'
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "guard-rake"
  spec.add_development_dependency "terminal-notifier-guard"
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_development_dependency 'guard-yard'
end
