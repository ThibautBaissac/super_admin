# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class CsvExportTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
    end

    test "should create csv export with valid attributes" do
      export = CsvExport.new(
        user: @user,
        resource_name: "posts",
        model_class_name: "Post",
        status: :pending
      )

      assert export.valid?
      assert export.save
    end

    test "should validate presence of required fields" do
  export = CsvExport.new
  export.status = nil

      assert_not export.valid?
      assert_includes export.errors[:resource_name], "can't be blank"
      assert_includes export.errors[:model_class_name], "can't be blank"
      assert_includes export.errors[:status], "can't be blank"
      assert_includes export.errors[:user], "must exist"
    end

    test "should generate token before create" do
      export = CsvExport.create!(
        user: @user,
        resource_name: "posts",
        model_class_name: "Post"
      )

      assert_not_nil export.token
      assert_equal 32, export.token.length
    end

    test "should validate token uniqueness" do
      token = "unique_token_123"

      export1 = CsvExport.create!(
        user: @user,
        resource_name: "posts",
        model_class_name: "Post",
        token: token
      )

      export2 = CsvExport.new(
        user: @user,
        resource_name: "users",
        model_class_name: "User",
        token: token
      )

      assert_not export2.valid?
      assert_includes export2.errors[:token], "has already been taken"
    end

    test "should have pending status by default" do
      export = CsvExport.create!(
        user: @user,
        resource_name: "posts",
        model_class_name: "Post"
      )

      assert export.pending_status?
    end

    test "should handle status transitions" do
      export = CsvExport.create!(
        user: @user,
        resource_name: "posts",
        model_class_name: "Post"
      )

      export.mark_processing!
      assert export.processing_status?
      assert_not_nil export.started_at

      export.mark_ready!(records_count: 100)
      assert export.ready_status?
      assert_equal 100, export.records_count
      assert_not_nil export.completed_at
      assert_not_nil export.expires_at

      export2 = CsvExport.create!(
        user: @user,
        resource_name: "users",
        model_class_name: "User"
      )

      export2.mark_failed!("Something went wrong")
      assert export2.failed_status?
      assert_equal "Something went wrong", export2.error_message
      assert_not_nil export2.completed_at
    end

    test "ready_for_download? should check status and file attachment" do
      export = CsvExport.create!(
        user: @user,
        resource_name: "posts",
        model_class_name: "Post"
      )

      assert_not export.ready_for_download?

      export.update!(status: :ready)
      assert_not export.ready_for_download? # No file attached

      # Simulate file attachment
      export.stub :file, OpenStruct.new(attached?: true) do
        assert export.ready_for_download?
      end
    end

    test "active scope should filter by expires_at" do
      active_export = CsvExport.create!(
        user: @user,
        resource_name: "posts",
        model_class_name: "Post",
        expires_at: 1.day.from_now
      )

      expired_export = CsvExport.create!(
        user: @user,
        resource_name: "users",
        model_class_name: "User",
        expires_at: 1.day.ago
      )

      active_exports = CsvExport.active
      assert_includes active_exports, active_export
      assert_not_includes active_exports, expired_export
    end

    test "recent_first scope should order by created_at desc" do
      old_export = CsvExport.create!(
        user: @user,
        resource_name: "posts",
        model_class_name: "Post",
        created_at: 2.days.ago
      )

      new_export = CsvExport.create!(
        user: @user,
        resource_name: "users",
        model_class_name: "User"
      )

      exports = CsvExport.recent_first.limit(2)
      assert_equal new_export.id, exports.first.id
      assert_equal old_export.id, exports.last.id
    end

    test "should use correct table name" do
      assert_equal "super_admin_csv_exports", CsvExport.table_name
    end

    test "should truncate long error messages" do
      export = CsvExport.create!(
        user: @user,
        resource_name: "posts",
        model_class_name: "Post"
      )

      long_error = "a" * 600
      export.mark_failed!(long_error)

      assert export.error_message.length <= 500
      assert export.error_message.ends_with?("...")
    end
  end
end
