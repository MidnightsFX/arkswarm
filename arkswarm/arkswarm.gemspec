require_relative 'lib/arkswarm/constants'

Gem::Specification.new do |spec|
  spec.name          = "arkswarm"
  spec.version       = Arkswarm::VERSION
  spec.authors       = ["Carl Creeden-Stutz"]
  spec.email         = ["carl.creeden.stutz@gmail.com"]

  spec.summary       = "Configuration, setup, and automation for running one or more ark servers in a dockerized environment."
  spec.description   = "Arkswarm is designed to handle some of the complex tasks of setting up, configuring, and automating frequent maintenance tasks for the game ARK: Survival Evolved."
  spec.homepage      = "https://github.com/MidnightsFX/arkswarm"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/MidnightsFX/arkswarm"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'thor', '~> 1.0.1'
end
