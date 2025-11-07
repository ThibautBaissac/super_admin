# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module AuthorizationAdapters
    class ProcAdapterTest < ActiveSupport::TestCase
      setup do
        @controller = Object.new
      end

      test "should authorize when proc returns true" do
        SuperAdmin.configure do |config|
          config.authorize_with = -> { true }
        end

        adapter = ProcAdapter.new(@controller)
        result = adapter.authorize(User.new)

        assert result
      end

      test "should deny when proc returns false" do
        SuperAdmin.configure do |config|
          config.authorize_with = -> { false }
        end

        adapter = ProcAdapter.new(@controller)
        result = adapter.authorize(User.new)

        assert_not result
      end

      test "should pass controller to proc" do
        controller_passed = nil

        SuperAdmin.configure do |config|
          config.authorize_with = ->(ctrl) { controller_passed = ctrl; true }
        end

        adapter = ProcAdapter.new(@controller)
        adapter.authorize(User.new)

        assert_equal @controller, controller_passed
      end

      test "should handle proc with resource parameter" do
        resource_passed = nil

        SuperAdmin.configure do |config|
          config.authorize_with = ->(ctrl, resource) { resource_passed = resource; true }
        end

        user = User.new
        adapter = ProcAdapter.new(@controller)
        adapter.authorize(user)

        assert_equal user, resource_passed
      end

      test "should return unscoped resources" do
        SuperAdmin.configure do |config|
          config.authorize_with = -> { true }
        end

        scope = User.all
        adapter = ProcAdapter.new(@controller)
        scoped = adapter.authorized_scope(scope)

        assert_equal scope, scoped
      end
    end
  end
end
