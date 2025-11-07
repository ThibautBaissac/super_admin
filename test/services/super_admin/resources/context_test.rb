# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module Resources
    class ContextTest < ActiveSupport::TestCase
      setup do
        @resource_name = "users"
        @context = Context.new(@resource_name)
      end

      test "should initialize with resource name" do
        assert_equal "users", @context.resource_name
      end

      test "should find model class from resource name" do
        assert_equal User, @context.model_class
      end

      test "should singularize resource name" do
        assert_equal "user", @context.singular_name
      end

      test "should pluralize resource name" do
        assert_equal "users", @context.plural_name
      end

      test "should resolve dashboard" do
        # Dashboard may or may not exist in test environment
        dashboard = @context.dashboard

        # If a dashboard exists, it should be a Class, otherwise nil
        assert(dashboard.nil? || dashboard.is_a?(Class),
               "Dashboard should be nil or a Class, got #{dashboard.class}")
      end

      test "should handle invalid resource name" do
        assert_raises(NameError) do
          Context.new("invalid_model").model_class
        end
      end

      test "should handle singular resource names" do
        context = Context.new("user")
        assert_equal User, context.model_class
        assert_equal "user", context.singular_name
        assert_equal "users", context.plural_name
      end

      test "should handle namespaced models" do
        # Create a namespaced model for testing
        unless defined?(SuperAdmin::TestModel)
          SuperAdmin.const_set(:TestModel, Class.new(ApplicationRecord) do
            self.table_name = "users"
          end)
        end

        context = Context.new("super_admin/test_models")
        assert_equal SuperAdmin::TestModel, context.model_class
      end
    end
  end
end
