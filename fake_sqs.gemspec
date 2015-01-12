# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fake_sqs/version'

Gem::Specification.new do |gem|
  gem.name          = "fake_sqs"
  gem.version       = FakeSQS::VERSION
  gem.authors       = ["iain"]
  gem.email         = ["iain@iain.nl"]
  gem.description   = %q{Provides a fake SQS server that you can run locally to test against}
  gem.summary       = %q{Provides a fake SQS server that you can run locally to test against}
  gem.homepage      = "https://github.com/iain/fake_sqs"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.license       = "MIT"

  gem.add_dependency "sinatra"
  gem.add_dependency "builder"
  gem.add_dependency "deep_merge"

  gem.add_development_dependency "rspec", "< 3.0"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "aws-sdk"
  gem.add_development_dependency "faraday"
  gem.add_development_dependency "thin"
  gem.add_development_dependency "verbose_hash_fetch"
  gem.add_development_dependency "activesupport"

end
