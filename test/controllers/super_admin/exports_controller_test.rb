# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class ExportsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @user = users(:one)
      SuperAdmin.configure do |config|
        config.user_class = "User"
        config.authenticate_with { true }
        config.authorize_with { true }
        config.current_user_method = -> { @user }
      end

      # Add csv_exports association to User if not already defined
      unless User.method_defined?(:csv_exports)
        User.class_eval do
          has_many :csv_exports, class_name: "SuperAdmin::CsvExport", foreign_key: :user_id
        end
      end

      @export = CsvExport.create!(
        user: @user,
        resource_name: "posts",
        model_class_name: "Post",
        status: :ready
      )
    end

    test "should get index" do
      get exports_url
      assert_response :success
      assert assigns(:exports).present?
    end

    test "should show export" do
      get export_url(@export.token)
      assert_response :success
    end

    test "should destroy export" do
      assert_difference("CsvExport.count", -1) do
        delete export_url(@export.token)
      end

      assert_redirected_to exports_url
    end

    test "should redirect when export not found" do
      get export_url("invalid_token")
      assert_redirected_to exports_url
      assert_not_nil flash[:alert]
    end

    test "should not download if export not ready" do
      @export.update!(status: :pending)

      get download_export_url(@export.token)
      assert_redirected_to exports_url
      assert_not_nil flash[:alert]
    end

    test "should not download if export expired" do
      @export.update!(expires_at: 1.day.ago)

      get download_export_url(@export.token)
      assert_redirected_to exports_url
      assert_not_nil flash[:alert]
    end

    test "should download export when ready" do
      filename_stub = Struct.new(:name) do
        def to_s
          name
        end
      end

      file_double = Struct.new(:data, :filename_obj, :content_type_value) do
        def download
          data
        end

        def filename
          filename_obj
        end

        def content_type
          content_type_value
        end
      end.new("csv,data", filename_stub.new("posts.csv"), "text/csv")

      export_stub = Struct.new(:token, :file, :expires_at) do
        def ready_for_download?
          true
        end
      end.new(@export.token, file_double, 1.day.from_now)

      finder = Class.new do
        def initialize(export)
          @export = export
        end

        def find_by(token:)
          @export if token == @export.token
        end
      end.new(export_stub)

      @user.stub :csv_exports, finder do
        get download_export_url(@export.token)
      end

      assert_response :success
      assert_equal "csv,data", response.body
      assert_equal "text/csv", response.media_type
      assert_match /attachment; filename=\"posts.csv\"/, response.headers["Content-Disposition"]
    end
  end
end
