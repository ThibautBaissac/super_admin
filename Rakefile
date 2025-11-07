# frozen_string_literal: true

require "bundler/gem_tasks"

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
load APP_RAKEFILE if File.exist?(APP_RAKEFILE)

load "rails/tasks/engine.rake"
load "rails/tasks/statistics.rake"

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = false
end

# Documentation with YARD
begin
  require "yard"
  YARD::Rake::YardocTask.new do |t|
    t.files = [ "app/**/*.rb", "lib/**/*.rb" ]
    t.options = [ "--markup", "markdown", "--readme", "README.md" ]
  end
rescue LoadError
  # YARD not available
end

task default: :test
