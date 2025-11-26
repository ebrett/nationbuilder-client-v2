# frozen_string_literal: true

require_relative "lib/nationbuilder_api/version"

Gem::Specification.new do |spec|
  spec.name = "nationbuilder-client-v2"
  spec.version = NationbuilderApi::VERSION
  spec.authors = ["Brett McHargue"]
  spec.email = ["ebrett@users.noreply.github.com"]

  spec.summary = "Ruby client for NationBuilder API v2 with OAuth 2.0 PKCE authentication"
  spec.description = "A Ruby gem providing OAuth 2.0 authentication, flexible token storage, and HTTP client infrastructure for the NationBuilder API v2. Includes seamless Rails integration and comprehensive error handling."
  spec.homepage = "https://github.com/ebrett/nationbuilder-client-v2"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ebrett/nationbuilder-client-v2"
  spec.metadata["changelog_uri"] = "https://github.com/ebrett/nationbuilder-client-v2/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/ebrett/nationbuilder-client-v2/issues"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/nationbuilder-client-v2"

  # Specify which files should be added to the gem when it is released.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ agent-os/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "base64", ">= 0.1.0" # Required for Ruby 3.4+
  spec.add_dependency "logger", ">= 1.4.0" # Required for Ruby 3.5+

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "webmock", "~> 3.19"
  spec.add_development_dependency "vcr", "~> 6.2"
  spec.add_development_dependency "standard", "~> 1.31"
end
