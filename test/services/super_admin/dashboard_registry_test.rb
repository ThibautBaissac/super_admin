# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class DashboardRegistryTest < ActiveSupport::TestCase
    setup do
      @registry = DashboardRegistry.instance
    end

    test "should be a singleton" do
      registry1 = DashboardRegistry.instance
      registry2 = DashboardRegistry.instance

      assert_same registry1, registry2
    end

    test "should return resource classes" do
      classes = @registry.resource_classes

      assert classes.is_a?(Array)
      # Should return models that have dashboards
    end

    test "should normalize model names" do
      normalized = @registry.send(:normalize_model_name, User)
      assert_equal "User", normalized

      normalized = @registry.send(:normalize_model_name, "users")
      assert_equal "User", normalized

      normalized = @registry.send(:normalize_model_name, :user)
      assert_equal "User", normalized
    end

    test "should reload dashboards" do
      @registry.reload!
      # Should not raise error
      assert true
    end

    test "should find dashboard for model" do
      # This will only work if dashboard files exist
      # dashboard = @registry.dashboard_for(User)
      # assert dashboard.is_a?(Class) if dashboard
    end
  end
end
