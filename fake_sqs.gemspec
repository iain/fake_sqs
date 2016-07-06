# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fake_sqs/version'

Gem::Specification.new do |gem|
  gem.name          = "fake_sqs"
  gem.version       = FakeSQS::VERSION
  gem.authors       = ["iain"]
  gem.email         = ["iain@iain.nl"]
  gem.summary       = %q{Provides a fake SQS server that you can run locally to test against}
  gem.homepage      = "https://github.com/iain/fake_sqs"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.license       = "MIT"


  gem.add_dependency "rack", "~> 2.0"
  gem.add_dependency "sinatra", "~> 2.0"
  gem.add_dependency "builder", "~> 3.2"

  gem.add_development_dependency "rspec", "~> 3.6"
  gem.add_development_dependency "rake", "~> 12.0"
  gem.add_development_dependency "rack-test", "~> 0.7"
  gem.add_development_dependency "aws-sdk", "~> 2.10"
  gem.add_development_dependency "thin", "~> 1.7"
  gem.add_development_dependency "verbose_hash_fetch", "~> 0.0"
  gem.add_development_dependency "activesupport", "~> 5.1"
end
