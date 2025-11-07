# frozen_string_literal: true

require_relative "lib/super_admin/version"

Gem::Specification.new do |spec|
  spec.name        = "super_admin"
  spec.version     = SuperAdmin::VERSION
  spec.authors     = [ "Thibaut Baissac" ]
  spec.email       = [ "tbaissac@gmail.com" ]

  spec.summary     = "A modern, flexible administration engine for Rails applications"
  spec.description = "SuperAdmin is a mountable Rails engine that provides a full-featured administration interface inspired by Administrate and ActiveAdmin, built for modern Rails 7+ applications."
  spec.homepage    = "https://github.com/ThibautBaissac/super_admin"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "documentation_uri" => "#{spec.homepage}#readme",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"].select do |path|
      File.file?(File.join(__dir__, path))
    end
  end

  spec.add_dependency "rails", ">= 7.1", "< 9.0"
  spec.add_dependency "pagy", ">= 9.0"
  spec.add_dependency "turbo-rails", ">= 2.0"
  spec.add_dependency "stimulus-rails", ">= 1.3"
  spec.add_dependency "rack-attack", ">= 6.0"
  spec.add_dependency "csv"
end
