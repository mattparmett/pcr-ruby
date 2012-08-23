# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pcr-ruby/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = "Matt Parmett"
  gem.email         = "parm289@yahoo.com"
  gem.description   = %q{Ruby wrapper for the Penn Course Review API}
  gem.summary       = %q{Ruby wrapper for the Penn Course Review API}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "pcr-ruby"
  gem.require_paths = ["lib"]
  gem.version       = Pcr::Ruby::VERSION
  
  gem.add_dependency "json"
end
