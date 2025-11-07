# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module Queries
    class ResourceScopeQueryTest < ActiveSupport::TestCase
      setup do
        User.delete_all

        @user1 = User.create!(email: "admin@example.com", name: "Admin User", role: :admin)
        @user2 = User.create!(email: "regular@example.com", name: "Regular User", role: :user)
        @user3 = User.create!(email: "another@example.com", name: "Another Admin", role: :admin)
      end

      test "should apply search filter" do
        scope = User.all
        result = ResourceScopeQuery.new(
          scope,
          query: "admin",
          filters: {},
          sort_column: nil,
          sort_direction: nil
        ).call

        assert result.count > 0
        assert result.any? { |u| u.email.include?("admin") || u.name.include?("Admin") }
      end

      test "should apply filters" do
        scope = User.all
        result = ResourceScopeQuery.new(
          scope,
          query: nil,
          filters: { "role_equals" => "admin" },
          sort_column: nil,
          sort_direction: nil
        ).call

        assert_equal 2, result.count
        assert result.all? { |u| u.role == "admin" }
      end

      test "should apply sorting" do
        scope = User.all
        result = ResourceScopeQuery.new(
          scope,
          query: nil,
          filters: {},
          sort_column: "name",
          sort_direction: "asc"
        ).call

        assert_equal "Admin User", result.first.name
        assert_equal "Regular User", result.last.name
      end

      test "should combine search, filter, and sort" do
        scope = User.all
        result = ResourceScopeQuery.new(
          scope,
          query: "admin",
          filters: { "role_equals" => "admin" },
          sort_column: "name",
          sort_direction: "desc"
        ).call

        assert_equal 2, result.count
        assert_equal "Another Admin", result.first.name
        assert_equal "Admin User", result.last.name
      end

      test "should handle empty parameters" do
        scope = User.all
        result = ResourceScopeQuery.new(
          scope,
          query: nil,
          filters: {},
          sort_column: nil,
          sort_direction: nil
        ).call

        assert_equal 3, result.count
      end

      test "should handle nil filters" do
        scope = User.all
        result = ResourceScopeQuery.new(
          scope,
          query: nil,
          filters: nil,
          sort_column: nil,
          sort_direction: nil
        ).call

        assert_equal 3, result.count
      end

      test "should preserve existing scope conditions" do
        scope = User.where(role: :admin)
        result = ResourceScopeQuery.new(
          scope,
          query: nil,
          filters: {},
          sort_column: nil,
          sort_direction: nil
        ).call

        assert_equal 2, result.count
        assert result.all? { |u| u.role == "admin" }
      end
    end
  end
end
