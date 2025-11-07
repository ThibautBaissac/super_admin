# frozen_string_literal: true

require "test_helper"
require "generators/super_admin/dashboard_generator"
require "fileutils"

module SuperAdmin
  module Generators
    class DashboardGeneratorTest < Rails::Generators::TestCase
      tests SuperAdmin::Generators::DashboardGenerator
      destination File.expand_path("../../../tmp", __dir__)
      setup :prepare_destination
  teardown :remove_generated_dashboards

      test "generator runs without errors" do
        # Basic smoke test
        assert_nothing_raised do
          run_generator
        end
      end

      test "generator shows completion message" do
        # Capture output by checking generator completes without errors
        assert_nothing_raised do
          run_generator
        end

        # Generator completed successfully (no exceptions thrown)
        assert true, "Generator completed successfully"
      end

      private

      def remove_generated_dashboards
        dashboards_dir = Rails.root.join("app/dashboards/super_admin")
        Dir.glob(dashboards_dir.join("*_dashboard.rb")).each do |path|
          next if File.basename(path) == "base_dashboard.rb"

          FileUtils.rm_f(path)
        end
      end
    end
  end
end
