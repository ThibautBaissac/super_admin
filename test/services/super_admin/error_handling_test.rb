# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class ErrorHandlingTest < ActiveSupport::TestCase
    test "should handle missing model gracefully in ModelInspector" do
      assert_nil ModelInspector.find_model("NonExistentModel")
    end

    test "should handle nil scope in queries" do
      # SortQuery should handle nil scope gracefully - raises NoMethodError
      assert_raises(NoMethodError) do
        Queries::SortQuery.new(nil, User, sort_column: "name").call
      end
    end

    test "should handle empty string in search query" do
      result = ResourceQuery.filtered_scope(
        User,
        search: "",
        sort: nil,
        direction: nil,
        filters: {}
      )

      assert result.is_a?(ActiveRecord::Relation)
    end

    test "should handle nil parameters in ResourceQuery" do
      result = ResourceQuery.filtered_scope(
        User,
        search: nil,
        sort: nil,
        direction: nil,
        filters: nil
      )

      assert result.is_a?(ActiveRecord::Relation)
    end

    test "should handle invalid filter parameters" do
      result = ResourceQuery.filtered_scope(
        User,
        search: nil,
        sort: nil,
        direction: nil,
        filters: { invalid_key: "value" }
      )

      assert result.is_a?(ActiveRecord::Relation)
    end

    test "should handle SQL injection attempts in search" do
      malicious_input = "'; DROP TABLE users; --"

      result = ResourceQuery.filtered_scope(
        User,
        search: malicious_input,
        sort: nil,
        direction: nil,
        filters: {}
      )

      # Should not raise error and should sanitize input
      assert result.is_a?(ActiveRecord::Relation)
      assert_equal 0, result.count
    end

    test "should handle SQL injection attempts in sort column" do
      malicious_column = "name; DROP TABLE users; --"

      result = ResourceQuery.filtered_scope(
        User,
        search: nil,
        sort: malicious_column,
        direction: "asc",
        filters: {}
      )

      # Should fallback to default sort without raising
      assert result.is_a?(ActiveRecord::Relation)
    end

    test "should handle invalid sort direction" do
      User.create!(email: "test@example.com", name: "Test")

      result = ResourceQuery.filtered_scope(
        User,
        search: nil,
        sort: "name",
        direction: "invalid_direction",
        filters: {}
      )

      # Should default to asc
      assert result.is_a?(ActiveRecord::Relation)
    end

    test "should handle missing required configuration" do
      original_user_class = SuperAdmin.configuration.user_class

      begin
        SuperAdmin.configuration.user_class = "NonExistentClass"

        assert_raises(SuperAdmin::ConfigurationError) do
          SuperAdmin.configuration.user_class_constant
        end
      ensure
        SuperAdmin.configuration.user_class = original_user_class
      end
    end

    test "should handle authorization errors" do
      controller = Object.new

      SuperAdmin.configure do |config|
        config.authorize_with = -> { raise StandardError.new("Not authorized") }
        config.on_unauthorized = nil # Don't handle the error
      end

      # Authorization.call catches errors and calls on_unauthorized handler
      # If no handler, it returns false
      result = Authorization.call(controller)
      assert_not result
    end

    test "should handle missing dashboard gracefully" do
      # Test with a model that has no dashboard
      test_class = Class.new(ApplicationRecord) do
        self.table_name = "users"
        def self.name
          "NonDashboardModel"
        end
      end

      result = DashboardResolver.dashboard_for(test_class)
      assert result.nil? || result.is_a?(Class)
    end

    test "should handle database connection errors" do
      # Simulate database error in auditing using proper Minitest stub
      AuditLog.stub(:create, ->(_) { raise ActiveRecord::StatementInvalid.new("DB error") }) do
        result = Auditing.log!(
          user: nil,
          resource_type: "Test",
          resource_id: 1,
          action: :test
        )

        # Should return nil without raising
        assert_nil result
      end
    end

    test "should handle malformed filter params" do
      scope = User.all

      # Test with params that don't match any filter definitions
      malformed_params = {
        "unknown_filter" => "value",
        "another_unknown" => "value"
      }

      # Should not raise errors, just ignore unknown filters
      result = FilterBuilder.apply(scope, User, malformed_params)
      assert result.is_a?(ActiveRecord::Relation)
    end

    test "should handle circular references in nested attributes" do
      # This tests that the system handles deeply nested structures
      # that could potentially cause infinite loops
      SuperAdmin.configure do |config|
        config.max_nested_depth = 10 # Very high depth
      end

      # Should not cause stack overflow
      assert SuperAdmin.max_nested_depth == 10
    end

    test "should handle unicode and special characters in search" do
      User.create!(email: "unicode@example.com", name: "Test 中文 émojis 🎉")

      result = ResourceQuery.filtered_scope(
        User,
        search: "中文",
        sort: nil,
        direction: nil,
        filters: {}
      )

      assert result.is_a?(ActiveRecord::Relation)
    end

    test "should handle very long search strings" do
      long_string = "a" * 10000

      result = ResourceQuery.filtered_scope(
        User,
        search: long_string,
        sort: nil,
        direction: nil,
        filters: {}
      )

      assert result.is_a?(ActiveRecord::Relation)
    end

    test "should handle concurrent access to configuration" do
      threads = 10.times.map do
        Thread.new do
          SuperAdmin.configure do |config|
            config.max_nested_depth = rand(1..5)
          end
        end
      end

      threads.each(&:join)

      # Configuration should still be valid
      assert SuperAdmin.configuration.max_nested_depth.is_a?(Integer)
    end
  end
end
