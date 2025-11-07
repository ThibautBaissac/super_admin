# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module Queries
    class SortQueryTest < ActiveSupport::TestCase
      setup do
        User.delete_all

        @users = [
          User.create!(email: "zebra@example.com", name: "Zebra"),
          User.create!(email: "alpha@example.com", name: "Alpha"),
          User.create!(email: "beta@example.com", name: "Beta")
        ]
      end

      test "should sort by column ascending" do
        scope = User.all
        sorted = SortQuery.new(scope, User, sort_column: "name", direction: "asc").call

        assert_equal "Alpha", sorted.first.name
        assert_equal "Zebra", sorted.last.name
      end

      test "should sort by column descending" do
        scope = User.all
        sorted = SortQuery.new(scope, User, sort_column: "name", direction: "desc").call

        assert_equal "Zebra", sorted.first.name
        assert_equal "Alpha", sorted.last.name
      end

      test "should default to ascending when direction not specified" do
        scope = User.all
        sorted = SortQuery.new(scope, User, sort_column: "name").call

        assert_equal "Alpha", sorted.first.name
      end

      test "should handle invalid column gracefully" do
        scope = User.all
        sorted = SortQuery.new(scope, User, sort_column: "invalid_column", direction: "asc").call

        # Should return default sort (by id desc)
        assert_equal 3, sorted.count
      end

      test "should handle invalid direction gracefully" do
        scope = User.all
        sorted = SortQuery.new(scope, User, sort_column: "name", direction: "invalid").call

        # Should default to asc
        assert_equal "Alpha", sorted.first.name
      end

      test "should return default sort when no column provided" do
        scope = User.all
        sorted = SortQuery.new(scope, User).call

        # Should sort by id desc by default
        assert_equal 3, sorted.count
      end

      test "should handle timestamp columns" do
        scope = User.all
        sorted = SortQuery.new(scope, User, sort_column: "created_at", direction: "desc").call

        # Most recently created should be first
        assert sorted.first.created_at >= sorted.last.created_at
      end

      test "should sanitize direction" do
        scope = User.all

        # Test with valid 'desc'
        desc_sorted = SortQuery.new(scope, User, sort_column: "name", direction: "desc").call
        assert_equal "Zebra", desc_sorted.first.name

        # Test with invalid direction defaults to asc
        invalid_sorted = SortQuery.new(scope, User, sort_column: "name", direction: "something").call
        assert_equal "Alpha", invalid_sorted.first.name
      end
    end
  end
end
