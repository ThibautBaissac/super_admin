# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module AuthorizationAdapters
    class DefaultAdapterTest < ActiveSupport::TestCase
      setup do
        @controller = Object.new
        @adapter = DefaultAdapter.new(@controller)
      end

      test "should always authorize" do
        user = User.new

        result = @adapter.authorize(user)
        assert result
      end

      test "should return unscoped resources" do
        scope = User.all

        scoped = @adapter.authorized_scope(scope)
        assert_equal scope, scoped
      end

      test "should work with any resource" do
        post = Post.new

        result = @adapter.authorize(post)
        assert result
      end

      test "should not raise errors" do
        assert_nothing_raised do
          @adapter.authorize(nil)
          @adapter.authorized_scope(nil)
        end
      end
    end
  end
end
