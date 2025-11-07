# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class AuditingTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
      @post = posts(:one)

      SuperAdmin.configure do |config|
        config.user_class = "User"
      end

      # Ensure audit log table exists
      unless AuditLog.table_exists?
        ActiveRecord::Migration.create_table :super_admin_audit_logs, force: true do |t|
          t.references :user, null: true
          t.string :user_email
          t.string :resource_type, null: false
          t.bigint :resource_id
          t.string :action, null: false
          t.json :changes_snapshot, default: {}
          t.json :context, default: {}
          t.datetime :performed_at, null: false
          t.timestamps
        end
      end
    end

    test "should create audit log for create action" do
      assert_difference("AuditLog.count", 1) do
        Auditing.log!(
          user: @user,
          resource: @post,
          action: :create,
          context: { ip: "127.0.0.1" }
        )
      end

      log = AuditLog.last
      assert_equal @user.id, log.user_id
      assert_equal "Post", log.resource_type
      assert_equal "create", log.action
    end

    test "should create audit log for update action" do
      @post.update(title: "Updated Title")

      assert_difference("AuditLog.count", 1) do
        Auditing.log!(
          user: @user,
          resource: @post,
          action: :update,
          changes: @post.previous_changes
        )
      end

      log = AuditLog.last
      assert_equal "update", log.action
      assert log.changes_snapshot.present?
    end

    test "should create audit log for destroy action" do
      assert_difference("AuditLog.count", 1) do
        Auditing.log!(
          user: @user,
          resource: @post,
          action: :destroy
        )
      end

      log = AuditLog.last
      assert_equal "destroy", log.action
    end

    test "should handle nil user gracefully" do
      assert_difference("AuditLog.count", 1) do
        Auditing.log!(
          user: nil,
          resource: @post,
          action: :create
        )
      end

      log = AuditLog.last
      assert_nil log.user_id
    end

    test "should extract user email" do
      Auditing.log!(
        user: @user,
        resource: @post,
        action: :create
      )

      log = AuditLog.last
      assert_equal @user.email, log.user_email
    end

    test "should not create audit log for AuditLog model" do
      assert_no_difference("AuditLog.count") do
        Auditing.log!(
          user: @user,
          resource_type: "SuperAdmin::AuditLog",
          resource_id: 1,
          action: :create
        )
      end
    end

    test "should sanitize changes to exclude updated_at" do
      changes = {
        "title" => [ "Old", "New" ],
        "updated_at" => [ 1.hour.ago, Time.current ]
      }

      Auditing.log!(
        user: @user,
        resource: @post,
        action: :update,
        changes: changes
      )

      log = AuditLog.last
      assert_not log.changes_snapshot.key?("updated_at")
      assert log.changes_snapshot.key?("title")
    end

    test "should handle errors gracefully" do
      # Force an error by stubbing
      AuditLog.stub :create, ->(_) { raise StandardError.new("test error") } do
        result = Auditing.log!(
          user: @user,
          resource: @post,
          action: :create
        )

        assert_nil result
      end
    end

    test "should allow custom context" do
      Auditing.log!(
        user: @user,
        resource: @post,
        action: :create,
        context: { ip: "192.168.1.1", user_agent: "Test Browser" }
      )

      log = AuditLog.last
      assert_equal "192.168.1.1", log.context["ip"]
      assert_equal "Test Browser", log.context["user_agent"]
    end

    test "should work with resource_type and resource_id directly" do
      assert_difference("AuditLog.count", 1) do
        Auditing.log!(
          user: @user,
          resource_type: "CustomModel",
          resource_id: 123,
          action: :custom_action
        )
      end

      log = AuditLog.last
  assert_equal "CustomModel", log.resource_type
  assert_equal "123", log.resource_id
      assert_equal "custom_action", log.action
    end
  end
end
