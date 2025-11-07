# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Development & test tooling

gem "sqlite3", "~> 2.8"

group :development, :test do
  gem "puma", "~> 7.1"
  gem "debug"
  gem "pry-rails"
  gem "rubocop", ">= 1.65", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "capybara", ">= 3.39"
  gem "minitest", ">= 5.0"
  gem "minitest-reporters"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "simplecov", require: false
end

group :development do
  gem "bullet"
  gem "yard", "~> 0.9", require: false
  gem "yard-rails", require: false
  gem "tailwindcss-rails", "~> 3.0", require: false
  gem "propshaft", "~> 1.0"
end
