# Configure SimpleCov for code coverage
require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"

  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Services", "app/services"
  add_group "Jobs", "app/jobs"
  add_group "Helpers", "app/helpers"
  add_group "Dashboards", "app/dashboards"

  add_filter "/lib/generators/"
  add_filter "/lib/super_admin/dashboard_creator.rb"
  add_filter "/lib/super_admin/install_task.rb"
  add_filter "/lib/super_admin/version.rb"
  add_filter "/lib/super_admin.rb"

  minimum_coverage 80 if ENV["CI"].present?
end

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"
require "minitest/reporters"
require "minitest/mock"

# Use spec-style reporter for better output
Minitest::Reporters.use! [
  Minitest::Reporters::SpecReporter.new,
  Minitest::Reporters::HtmlReporter.new(
    reports_dir: "test/reports",
    reports_title: "SuperAdmin Test Results"
  )
]

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

# Helper methods for tests
class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def create_test_user(attributes = {})
    User.create!({
      email: "test#{rand(1000)}@example.com",
      name: "Test User"
    }.merge(attributes))
  end

  def stub_authorization(authorized: true)
    SuperAdmin.configure do |config|
      config.authorize_with { authorized }
    end
  end

  def stub_authentication(user: nil)
    SuperAdmin.configure do |config|
      config.authenticate_with { user }
      config.current_user_method = -> { user }
    end
  end
end

class ActionDispatch::IntegrationTest
  # Make the helpers available to integration tests
  include ActiveSupport::Testing::TimeHelpers

  def assigns(key = nil)
    controller = @integration_session&.controller
    return if controller.nil?

    variables = controller.instance_variables.each_with_object({}) do |ivar, memo|
      next if ivar.to_s.start_with?("@_")

      memo[ivar.to_s.delete_prefix("@").to_sym] = controller.instance_variable_get(ivar)
    end

    key ? variables[key.to_sym] : variables
  end
end

 # Ensure test User model exposes CSV export association for creator and controller specs.
 unless defined?(User) && User.method_defined?(:csv_exports)
   User.class_eval do
     has_many :csv_exports, class_name: "SuperAdmin::CsvExport", foreign_key: :user_id
   end
 end
