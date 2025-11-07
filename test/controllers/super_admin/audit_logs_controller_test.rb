# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class AuditLogsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @user = users(:one)
      SuperAdmin.configure do |config|
        config.user_class = "User"
        config.authenticate_with { true }
        config.authorize_with { true }
      end

      # Ensure audit log table exists
      unless AuditLog.table_exists?
        ActiveRecord::Migration.create_table :super_admin_audit_logs do |t|
          t.references :user, null: true
          t.string :resource_type, null: false
          t.bigint :resource_id
          t.string :action, null: false
          t.json :changes_snapshot, default: {}
          t.json :context, default: {}
          t.datetime :performed_at, null: false
          t.timestamps
        end
      end

      @audit_log = AuditLog.create!(
        user: @user,
        resource_type: "Post",
        resource_id: 1,
        action: "create",
        changes_snapshot: { title: "New Post" },
        context: { ip: "127.0.0.1" },
        performed_at: Time.current
      )
    end

    test "should get index" do
      get audit_logs_url
      assert_response :success
    end

    test "should filter by action_type" do
      AuditLog.create!(
        resource_type: "User",
        action: "update",
        performed_at: Time.current
      )

      get audit_logs_url(action_type: "create")
      assert_response :success
      # Should only show 'create' actions
    end

    test "should filter by resource_type" do
      AuditLog.create!(
        resource_type: "User",
        action: "create",
        performed_at: Time.current
      )

      get audit_logs_url(resource_type: "Post")
      assert_response :success
      # Should only show Post resources
    end

    test "should search audit logs" do
      get audit_logs_url(query: "Post")
      assert_response :success
    end

    test "should paginate results" do
      # Create multiple audit logs
      30.times do |i|
        AuditLog.create!(
          resource_type: "Post",
          resource_id: i,
          action: "create",
          performed_at: Time.current
        )
      end

      get audit_logs_url
      assert_response :success
      assert assigns(:pagy).present?
      assert assigns(:audit_logs).present?
    end

    test "should redirect if audit log table does not exist" do
      AuditLog.stub :table_exists?, false do
        get audit_logs_url
        assert_redirected_to root_url
        assert_not_nil flash[:alert]
      end
    end
  end
end
