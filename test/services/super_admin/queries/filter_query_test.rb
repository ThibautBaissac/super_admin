# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module Queries
    class FilterQueryTest < ActiveSupport::TestCase
      setup do
        User.delete_all

        @user1 = User.create!(email: "user1@example.com", name: "User One", role: :user, active: true)
        @user2 = User.create!(email: "admin@example.com", name: "Admin", role: :admin, active: true)
        @inactive = User.create!(email: "inactive@example.com", name: "Inactive", role: :user, active: false)
      end

      test "should filter by role" do
        scope = User.all
  filters = { "role_equals" => "admin" }
        query = FilterQuery.new(scope, User, filters)
        results = query.call

        assert_includes results, @user2
        assert_not_includes results, @user1
      end

      test "should filter by active status" do
        scope = User.all
  filters = { "active_equals" => "false" }
        query = FilterQuery.new(scope, User, filters)
        results = query.call

        assert_includes results, @inactive
        assert_not_includes results, @user1
      end

      test "should return all when no filters" do
        scope = User.all
        query = FilterQuery.new(scope, User, {})
        results = query.call

        assert_equal 3, results.count
      end

      test "should handle multiple filters" do
        scope = User.all
  filters = { "role_equals" => "user", "active_equals" => "true" }
        query = FilterQuery.new(scope, User, filters)
        results = query.call

        assert_includes results, @user1
        assert_not_includes results, @user2
        assert_not_includes results, @inactive
      end
    end
  end
end
