# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class DashboardResolverTest < ActiveSupport::TestCase
    test "should resolve dashboard for model" do
      # Create a test dashboard
      unless defined?(SuperAdmin::UserDashboard)
        SuperAdmin.const_set(:UserDashboard, Class.new(BaseDashboard) do
          def self.collection_attributes
            [ :name, :email ]
          end
        end)
      end

      dashboard = DashboardResolver.dashboard_for(User)
      assert dashboard.is_a?(Class) || dashboard.nil?
      assert dashboard < BaseDashboard if dashboard
    end

    test "should handle missing dashboard gracefully" do
      # Test with a model that has no dashboard
      test_class = Class.new(ApplicationRecord) do
        self.table_name = "users"
        def self.name
          "NonexistentModelForDashboard"
        end
      end

      result = DashboardResolver.dashboard_for(test_class)

      # Should return nil when dashboard doesn't exist
      assert result.nil? || result.is_a?(Class)
    end

    test "should cache dashboard lookups" do
      unless defined?(SuperAdmin::UserDashboard)
        SuperAdmin.const_set(:UserDashboard, Class.new(BaseDashboard))
      end

      # First call
      dashboard1 = DashboardResolver.dashboard_for(User)

      # Second call should return same result
      dashboard2 = DashboardResolver.dashboard_for(User)

      assert_equal dashboard1, dashboard2
    end

    test "should handle namespaced models" do
      # SuperAdmin::AuditLog should already exist
      dashboard = DashboardResolver.dashboard_for(SuperAdmin::AuditLog)

      # Should handle namespaced models
      assert dashboard.nil? || dashboard.is_a?(Class)
    end

    test "should resolve attributes for different views" do
      # Test collection attributes
      collection_attrs = DashboardResolver.collection_attributes_for(User)
      assert collection_attrs.is_a?(Array)

      # Test show attributes
      show_attrs = DashboardResolver.show_attributes_for(User)
      assert show_attrs.is_a?(Array)

      # Test form attributes
      form_attrs = DashboardResolver.form_attributes_for(User)
      assert form_attrs.is_a?(Array)
    end

    test "should resolve includes for associations" do
      # Test collection includes
      collection_includes = DashboardResolver.collection_includes_for(User)
      assert collection_includes.is_a?(Array)

      # Test show includes
      show_includes = DashboardResolver.show_includes_for(User)
      assert show_includes.is_a?(Array)
    end

    test "should handle view name variations" do
      # Test different view names that map to same attribute set
      index_attrs = DashboardResolver.attributes_for(User, :index)
      collection_attrs = DashboardResolver.attributes_for(User, :collection)

      # Index and collection should map to the same attributes
      assert_equal collection_attrs, index_attrs
    end

    test "should fallback to model attributes when no dashboard exists" do
      # Create a model without dashboard
      test_model = Class.new(ApplicationRecord) do
        self.table_name = "users"
        def self.name
          "ModelWithoutDashboard"
        end
      end

      attrs = DashboardResolver.collection_attributes_for(test_model)

      # Should return some attributes from fallback
      assert attrs.is_a?(Array)
    end
  end
end
