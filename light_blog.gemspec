# frozen_string_literal: true

require_relative "lib/light_blog/version"

Gem::Specification.new do |spec|
  spec.name = "light_blog"
  spec.version = LightBlog::VERSION
  spec.authors = ["Rodrigo Rosenfeld Rosas"]
  spec.email = ["rr.rosas@gmail.com"]

  spec.summary = "Light Blog app built on top of Roda"
  spec.homepage = "https://gitlab.com/rr.rosas/light_blog"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://gitlab.com/rr.rosas/light_blog"
  spec.metadata["changelog_uri"] = "https://gitlab.com/rr.rosas/light_blog/-/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "erubi"
  spec.add_dependency "rdiscount" # Markdown processor
  spec.add_dependency "roda"
  spec.add_dependency "rouge" # code highlighting
  spec.add_dependency "rss" # to generate the Atom feed
  spec.add_dependency "tilt"
  spec.add_dependency "yaml" # to load articles' headers
  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  spec.add_runtime_dependency "listen"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
