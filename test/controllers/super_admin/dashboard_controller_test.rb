# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @user = users(:one)
      # Configure SuperAdmin to use test User model
      SuperAdmin.configure do |config|
        config.user_class = "User"
        config.authenticate_with { true }
        config.authorize_with { true }
      end

      # Create test dashboards
      @routes = Rails.application.routes
      @routes.disable_clear_and_finalize = true
      @routes.clear!
      Rails.application.routes_reloader.paths.each { |path| load(path) }
      @routes.finalize!
    end

    teardown do
      @routes.disable_clear_and_finalize = false
    end

    test "should get index" do
      get root_url
      assert_response :success
    end

    test "should display available models" do
      get root_url
      assert_response :success
      assert_select "body" # Basic HTML check
    end

    test "should handle model count errors gracefully" do
      # Stub a model to raise error on count
      User.stub :count, -> { raise ActiveRecord::StatementInvalid.new("test error") } do
        get root_url
        assert_response :success
        # Should still render but with 0 count for that model
      end
    end

    test "should display model information" do
      get root_url
      assert_response :success
      assert assigns(:models_info).is_a?(Array)
    end
  end
end
