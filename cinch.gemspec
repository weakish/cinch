# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cinch/version'

Gem::Specification.new do |spec|
  spec.name          = "cinch"
  spec.version       = Cinch::VERSION
  spec.authors       = ["Jakukyo Friel"]
  spec.email         = ["weakish@gmail.com"]
  spec.summary       = %q{A manager of big files.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.bindir        = 'bin'

  spec.add_runtime_dependency 'clik', '~> 0.1'
  spec.add_runtime_dependency 'oj', '~> 2.11'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
