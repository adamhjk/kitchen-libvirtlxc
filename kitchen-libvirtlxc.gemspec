# coding: utf-8
Gem::Specification.new do |spec|
  spec.name          = "kitchen-libvirtlxc"
  spec.version       = "0.1.0"
  spec.authors       = ["Adam Jacob"]
  spec.email         = ["adam@opscode.com"]
  spec.description   = %q{Kitchen driver for libvirt LXC containers}
  spec.summary       = %q{Kitchen driver for libvirt LXC containers}
  spec.homepage      = "http://github.com/adamhjk/kitchen-libvirtlxc"
  spec.license       = "Apache 2"
  spec.has_rdoc      = false

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency("test-kitchen", ">= 1.0.0.alpha.6")

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
