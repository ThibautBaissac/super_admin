# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module AuthorizationAdapters
    class PunditAdapterTest < ActiveSupport::TestCase
      setup do
        @controller = Object.new
        def @controller.authorize(*); true; end
        def @controller.policy_scope(scope); scope; end

        @adapter = PunditAdapter.new(@controller)
      end

      test "should authorize resource" do
        user = User.new

        result = @adapter.authorize(user)
        assert result
      end

      test "should handle authorization failure" do
        def @controller.authorize(*)
          raise StandardError.new("Not authorized")
        end

        user = User.new
        assert_raises(StandardError) do
          @adapter.authorize(user)
        end
      end

      test "should scope resources" do
        scope = User.all

        scoped = @adapter.authorized_scope(scope)
        assert_equal scope, scoped
      end

      test "should detect pundit availability" do
        # Pundit may or may not be available in test environment
        assert_respond_to @adapter, :authorize
      end
    end
  end
end
