# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'db_facet/version'

Gem::Specification.new do |spec|
  spec.name          = "db_facet"
  spec.version       = DbFacet::VERSION
  spec.authors       = ["Tom Lobato"]
  spec.email         = ["tomlobato@gmail.com"]

  spec.summary       = %q{db_facet extracts and inserts subsets of a database content, like a full user account with all its photos, invoices and history.}
  spec.description   = %q{db_facet extracts and inserts subsets of a database content, like a full user account with all its photos, invoices and history..}
  spec.homepage      = "https://tomlobato.github.io/db_facet/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_runtime_dependency "activerecord-import", "~> 0.19.1"
end
