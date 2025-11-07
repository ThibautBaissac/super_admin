# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class ResourcesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @user = users(:one)
      SuperAdmin.configure do |config|
        config.user_class = "User"
        config.authenticate_with { true }
        config.authorize_with { true }
        config.current_user_method = -> { @user }
      end

      # Ensure we have test data
      @test_user = User.create!(email: "resourcetest@example.com", name: "Resource Test")
    end

    test "should get index for resource" do
      get resources_path("users")
      assert_response :success
    end

    test "should get new for resource" do
      get new_resource_path("users")
      assert_response :success
    end

    test "should create resource" do
      assert_difference("User.count", 1) do
        post resources_path("users"), params: {
          user: {
            email: "newuser@example.com",
            name: "New User"
          }
        }
      end

      assert_redirected_to resource_path("users", User.last)
    end

    test "should show resource" do
      get resource_path("users", @test_user)
      assert_response :success
    end

    test "should get edit for resource" do
      get edit_resource_path("users", @test_user)
      assert_response :success
    end

    test "should update resource" do
      patch resource_path("users", @test_user), params: {
        user: {
          name: "Updated Name"
        }
      }

      assert_redirected_to resource_path("users", @test_user)
      @test_user.reload
      assert_equal "Updated Name", @test_user.name
    end

    test "should destroy resource" do
      user_to_delete = User.create!(email: "delete@example.com", name: "Delete Me")

      assert_difference("User.count", -1) do
        delete resource_path("users", user_to_delete)
      end

      assert_redirected_to resources_path("users")
    end

    test "should handle invalid resource name" do
      assert_raises(NameError) do
        get resources_path("invalid_resource")
      end
    end

    test "should filter resources" do
  User.create!(email: "admin_filter@example.com", name: "Admin", role: :admin)

      get resources_path("users"), params: { filter: { role: "admin" } }
      assert_response :success
    end

    test "should search resources" do
      get resources_path("users"), params: { query: "resource" }
      assert_response :success
    end

    test "should sort resources" do
      get resources_path("users"), params: { sort: "name", direction: "asc" }
      assert_response :success
    end

    test "should handle validation errors on create" do
      assert_no_difference("User.count") do
        post resources_path("users"), params: {
          user: {
            email: "", # Invalid - required field
            name: "Test"
          }
        }
      end

      assert_response :unprocessable_entity
    end

    test "should handle validation errors on update" do
      patch resource_path("users", @test_user), params: {
        user: {
          email: "" # Invalid - required field
        }
      }

      assert_response :unprocessable_entity
    end

    test "should create audit log on create" do
      assert_difference("AuditLog.count", 1) do
        post resources_path("users"), params: {
          user: {
            email: "audit@example.com",
            name: "Audit Test"
          }
        }
      end

      log = AuditLog.last
      assert_equal "User", log.resource_type
      assert_equal "create", log.action
    end

    test "should create audit log on update" do
      assert_difference("AuditLog.count", 1) do
        patch resource_path("users", @test_user), params: {
          user: {
            name: "Updated via Audit"
          }
        }
      end

      log = AuditLog.last
      assert_equal "update", log.action
    end

    test "should create audit log on destroy" do
      user_to_delete = User.create!(email: "auditdelete@example.com", name: "Audit Delete")

      assert_difference("AuditLog.count", 1) do
        delete resource_path("users", user_to_delete)
      end

      log = AuditLog.last
      assert_equal "destroy", log.action
    end
  end
end
