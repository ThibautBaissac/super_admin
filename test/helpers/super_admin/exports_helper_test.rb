# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class ExportsHelperTest < ActionView::TestCase
    setup do
      @user = users(:one)
    end

    test "export_badge_classes returns correct class for pending status" do
      export = CsvExport.new(
        user: @user,
        resource_name: "users",
        model_class_name: "User",
        status: :pending
      )

      assert_equal "bg-yellow-100 text-yellow-800", export_badge_classes(export)
    end

    test "export_badge_classes returns correct class for processing status" do
      export = CsvExport.new(
        user: @user,
        resource_name: "users",
        model_class_name: "User",
        status: :processing
      )

      assert_equal "bg-blue-100 text-blue-800", export_badge_classes(export)
    end

    test "export_badge_classes returns correct class for ready status" do
      export = CsvExport.new(
        user: @user,
        resource_name: "users",
        model_class_name: "User",
        status: :ready
      )

      assert_equal "bg-green-100 text-green-800", export_badge_classes(export)
    end

    test "export_badge_classes returns correct class for failed status" do
      export = CsvExport.new(
        user: @user,
        resource_name: "users",
        model_class_name: "User",
        status: :failed
      )

      assert_equal "bg-red-100 text-red-800", export_badge_classes(export)
    end

    test "export_badge_classes returns default class for unknown status" do
      export = Struct.new(:status).new("unknown_status")

      assert_equal "bg-gray-100 text-gray-800", export_badge_classes(export)
    end
  end
end
