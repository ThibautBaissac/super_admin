# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class AssociationsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @user = users(:one)
      SuperAdmin.configure do |config|
        config.user_class = "User"
        config.authenticate_with { true }
        config.authorize_with { true }
        config.association_pagination_limit = 10
      end

      # Create test users for search
      5.times do |i|
        User.create!(
          email: "searchuser#{i}@example.com",
          name: "Search User #{i}",
          role: :user
        )
      end
    end

    test "should search associations successfully" do
      get association_search_url(model: "User", q: "Search")
      assert_response :success

      json = JSON.parse(response.body)
      assert json["results"].is_a?(Array)
      assert json["pagination"].present?
    end

    test "should return error for invalid model" do
      get association_search_url(model: "InvalidModel")
      assert_response :not_found

      json = JSON.parse(response.body)
      assert_equal "Model not found", json["error"]
    end

    test "should paginate results" do
      get association_search_url(model: "User", page: 1)
      assert_response :success

      json = JSON.parse(response.body)
      assert json["pagination"]["page"] == 1
      assert json["pagination"].key?("more")
      assert json["pagination"].key?("total")
    end

    test "should filter by query" do
      get association_search_url(model: "User", q: "user1@example.com")
      assert_response :success

      json = JSON.parse(response.body)
      assert json["results"].any? { |r| r["text"].include?("user1") }
    end

    test "should include selected record" do
      user = User.first
      get association_search_url(model: "User", selected_id: user.id, page: 1)
      assert_response :success

      json = JSON.parse(response.body)
      assert json["results"].first["id"] == user.id
    end

    test "should handle search errors gracefully" do
      # Force an error by stubbing
      ModelInspector.stub :find_model, ->(_) { raise StandardError.new("test error") } do
        get association_search_url(model: "User")
        assert_response :internal_server_error

        json = JSON.parse(response.body)
        assert_equal "Search failed", json["error"]
      end
    end

    test "should sanitize output to prevent XSS" do
      User.create!(
        email: "xss@example.com",
        name: "<script>alert('xss')</script>",
        role: :user
      )

      get association_search_url(model: "User", q: "xss")
      assert_response :success

      json = JSON.parse(response.body)
      # Output should be HTML-escaped
      assert_not response.body.include?("<script>")
    end
  end
end
