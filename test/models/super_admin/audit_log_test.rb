# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class AuditLogTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
      SuperAdmin.configure do |config|
        config.user_class = "User"
      end
    end

    test "should create audit log with valid attributes" do
      audit_log = AuditLog.new(
        user: @user,
        resource_type: "Post",
        resource_id: 1,
        action: "create",
        changes_snapshot: { title: "New Post" },
        context: { ip: "127.0.0.1" }
      )

      assert audit_log.valid?
      assert audit_log.save
    end

    test "should validate presence of required fields" do
      audit_log = AuditLog.new

      assert_not audit_log.valid?
      assert_includes audit_log.errors[:resource_type], "can't be blank"
      assert_includes audit_log.errors[:action], "can't be blank"
      assert_includes audit_log.errors[:performed_at], "can't be blank"
    end

    test "should allow optional user" do
      audit_log = AuditLog.new(
        resource_type: "Post",
        resource_id: 1,
        action: "destroy",
        changes_snapshot: {},
        context: {}
      )

      assert audit_log.valid?
    end

    test "should set default performed_at before validation" do
      audit_log = AuditLog.new(
        resource_type: "Post",
        action: "update"
      )

      audit_log.valid?
      assert_not_nil audit_log.performed_at
    end

    test "should set default payloads before validation" do
      audit_log = AuditLog.new(
        resource_type: "Post",
        action: "update"
      )

      audit_log.valid?
      assert_equal({}, audit_log.changes_snapshot)
      assert_equal({}, audit_log.context)
    end

    test "recent scope should order by performed_at desc" do
      old_log = AuditLog.create!(
        resource_type: "Post",
        action: "create",
        performed_at: 2.days.ago
      )

      new_log = AuditLog.create!(
        resource_type: "Post",
        action: "update",
        performed_at: 1.hour.ago
      )

      recent_logs = AuditLog.recent.limit(2)
      assert_equal new_log.id, recent_logs.first.id
      assert_equal old_log.id, recent_logs.last.id
    end

    test "should use correct table name" do
      assert_equal "super_admin_audit_logs", AuditLog.table_name
    end
  end
end
