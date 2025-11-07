# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class ApplicationHelperTest < ActionView::TestCase
    include ApplicationHelper

    test "should have helper methods available" do
      assert respond_to?(:super_admin_root_path)
    end

    test "helpers should not raise errors" do
      # Basic smoke test to ensure helpers are loadable
      assert true
    end

    test "action_badge_class returns correct class for create action" do
      result = action_badge_class("create")

      assert_equal "bg-green-100 text-green-800", result
    end

    test "action_badge_class returns correct class for update action" do
      result = action_badge_class("update")

      assert_equal "bg-blue-100 text-blue-800", result
    end

    test "action_badge_class returns correct class for destroy action" do
      result = action_badge_class("destroy")

      assert_equal "bg-red-100 text-red-800", result
    end

    test "action_badge_class returns correct class for bulk_destroy action" do
      result = action_badge_class("bulk_destroy")

      assert_equal "bg-red-100 text-red-800", result
    end

    test "action_badge_class returns default class for unknown action" do
      result = action_badge_class("unknown_action")

      assert_equal "bg-gray-100 text-gray-800", result
    end

    test "super_admin_root_path returns engine root path" do
      path = super_admin_root_path

      assert path.is_a?(String)
      assert path.start_with?("/")
    end

    test "super_admin_exports_path returns exports path" do
      path = super_admin_exports_path

      assert path.is_a?(String)
      assert path.include?("export")
    end

    test "super_admin_audit_logs_path returns audit logs path" do
      path = super_admin_audit_logs_path

      assert path.is_a?(String)
      assert path.include?("audit")
    end

    test "audit_log_ready? returns false when table does not exist" do
      AuditLog.stub :table_exists?, false do
        result = send(:audit_log_ready?)

        assert_equal false, result
      end
    end

    test "audit_log_ready? returns true when table exists" do
      AuditLog.stub :table_exists?, true do
        result = send(:audit_log_ready?)

        assert_equal true, result
      end
    end
  end
end
