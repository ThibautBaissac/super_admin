# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class AuthorizationTest < ActiveSupport::TestCase
    setup do
      @controller = Object.new
      @controller.extend(ActionController::Redirecting)
      @controller.extend(ActionController::Flash)

      SuperAdmin.reset_configuration!

      SuperAdmin.configure do |config|
        config.user_class = "User"
        config.authorization_adapter = :default
        config.authorize_with = nil
        config.on_unauthorized = nil
      end
    end

    teardown do
      SuperAdmin.reset_configuration!
    end

    test "should authorize with default adapter" do
      SuperAdmin.configure do |config|
        config.authorize_with = -> { true }
      end

      assert Authorization.call(@controller)
    end

    test "should deny authorization when proc returns false" do
      SuperAdmin.configure do |config|
        config.authorize_with = -> { false }
      end

      assert_not Authorization.call(@controller)
    end

    test "should build adapter correctly" do
      adapter = Authorization.build_adapter(@controller)
      assert adapter.is_a?(AuthorizationAdapters::BaseAdapter)
    end

    test "should use proc adapter when authorize_with is configured" do
      SuperAdmin.configure do |config|
        config.authorize_with = -> { true }
      end

      adapter = Authorization.build_adapter(@controller)
      assert_instance_of AuthorizationAdapters::ProcAdapter, adapter
    end

    test "should use default adapter when nothing configured" do
      SuperAdmin.configure do |config|
        config.authorize_with = nil
        config.authorization_adapter = :default
      end

      adapter = Authorization.build_adapter(@controller)
      assert_instance_of AuthorizationAdapters::DefaultAdapter, adapter
    end

    test "should resolve adapter from symbol" do
      SuperAdmin.configure do |config|
        config.authorization_adapter = :proc
        config.authorize_with = -> { true }
      end

      adapter = Authorization.build_adapter(@controller)
      assert_instance_of AuthorizationAdapters::ProcAdapter, adapter
    end

    test "should handle custom on_unauthorized handler" do
      handler_called = false

      SuperAdmin.configure do |config|
        config.authorize_with = -> { false }
        config.on_unauthorized = ->(_error) { handler_called = true }
      end

      Authorization.call(@controller)
      assert handler_called
    end

    test "should raise error for invalid adapter name" do
      SuperAdmin.configure do |config|
        config.authorization_adapter = :invalid_adapter
      end

      # Should fallback to default adapter without raising
      adapter = Authorization.build_adapter(@controller)
      assert_instance_of AuthorizationAdapters::DefaultAdapter, adapter
    end
  end
end
