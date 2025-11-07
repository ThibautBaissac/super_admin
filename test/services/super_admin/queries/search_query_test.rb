# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module Queries
    class SearchQueryTest < ActiveSupport::TestCase
      setup do
        User.delete_all

        @user1 = User.create!(email: "alice@example.com", name: "Alice Smith", role: :user)
        @user2 = User.create!(email: "bob@example.com", name: "Bob Johnson", role: :admin)
        @user3 = User.create!(email: "charlie@example.com", name: "Charlie Brown", role: :user)
      end

      test "should search by name" do
        scope = User.all
        query = SearchQuery.new(scope, "Alice")
        results = query.call

        assert_includes results, @user1
        assert_not_includes results, @user2
      end

      test "should search by email" do
        scope = User.all
        query = SearchQuery.new(scope, "bob@")
        results = query.call

        assert_includes results, @user2
        assert_not_includes results, @user1
      end

      test "should be case insensitive" do
        scope = User.all
        query = SearchQuery.new(scope, "ALICE")
        results = query.call

        assert_includes results, @user1
      end

      test "should return all results when query is blank" do
        scope = User.all
        query = SearchQuery.new(scope, "")
        results = query.call

        assert_equal 3, results.count
      end

      test "should return empty when no matches" do
        scope = User.all
        query = SearchQuery.new(scope, "nonexistent")
        results = query.call

        assert_equal 0, results.count
      end
    end
  end
end
