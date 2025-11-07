# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class ResourceQueryTest < ActiveSupport::TestCase
    setup do
      User.delete_all

      @users = [
        User.create!(email: "alice@example.com", name: "Alice", role: :admin),
        User.create!(email: "bob@example.com", name: "Bob", role: :user),
        User.create!(email: "charlie@example.com", name: "Charlie", role: :admin)
      ]
    end

    test "should apply search query" do
      results = ResourceQuery.filtered_scope(
        User,
        search: "alice",
        sort: nil,
        direction: nil,
        filters: {}
      )

      assert results.any? { |u| u.email.include?("alice") }
    end

    test "should apply filters" do
      results = ResourceQuery.filtered_scope(
        User,
        search: nil,
        sort: nil,
        direction: nil,
        filters: { role_equals: "admin" }
      )

      assert_equal 2, results.count
      assert results.all? { |u| u.role == "admin" }
    end

    test "should apply sorting" do
      results = ResourceQuery.filtered_scope(
        User,
        search: nil,
        sort: "name",
        direction: "asc",
        filters: {}
      )

      assert_equal "Alice", results.first.name
      assert_equal "Charlie", results.last.name
    end

    test "should combine search and filters" do
      results = ResourceQuery.filtered_scope(
        User,
        search: "example.com",
        sort: nil,
        direction: nil,
        filters: { role_equals: "admin" }
      )

      assert results.count >= 1
      assert results.all? { |u| u.role == "admin" }
    end

    test "should handle empty params" do
      results = ResourceQuery.filtered_scope(
        User,
        search: nil,
        sort: nil,
        direction: nil,
        filters: {}
      )

      assert_equal 3, results.count
    end

    test "should return active record relation" do
      results = ResourceQuery.filtered_scope(
        User,
        search: nil,
        sort: nil,
        direction: nil,
        filters: {}
      )

      assert results.is_a?(ActiveRecord::Relation)
    end

    test "should apply deprecated search method" do
      scope = User.all
      results = ResourceQuery.apply_search(scope, User, "alice")

      assert results.is_a?(ActiveRecord::Relation)
    end

    test "should apply deprecated sort method" do
      scope = User.all
      results = ResourceQuery.apply_sort(scope, User, "name", "asc")

      assert results.is_a?(ActiveRecord::Relation)
    end
  end
end
