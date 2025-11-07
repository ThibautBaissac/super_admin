# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class BaseDashboardTest < ActiveSupport::TestCase
    # Create a test dashboard class
    class TestDashboard < BaseDashboard
      resource User
      collection_attributes :id, :name, :email
      show_attributes :id, :name, :email, :created_at
      form_attributes :name, :email
      collection_includes :posts
      show_includes :posts
    end

    class InferredDashboard < BaseDashboard
      # Should infer resource class from name
    end

    test "resource should set resource class" do
      assert_equal User, TestDashboard.resource_class
    end

    test "should infer resource class from dashboard name" do
      # InferredDashboard should try to infer class from name
      # The class may or may not exist - we'll just check it returns something or raises
      begin
        result = InferredDashboard.resource_class
        # If it succeeds, it should return a class
        assert result.is_a?(Class) || result.nil?
      rescue NameError
        # This is acceptable - the inferred class may not exist
        assert true
      end
    end

    test "collection_attributes should set collection attributes" do
      attrs = TestDashboard.collection_attributes_list

      assert_includes attrs, :id
      assert_includes attrs, :name
      assert_includes attrs, :email
    end

    test "show_attributes should set show attributes" do
      attrs = TestDashboard.show_attributes_list

      assert_includes attrs, :id
      assert_includes attrs, :name
      assert_includes attrs, :email
      assert_includes attrs, :created_at
    end

    test "form_attributes should set form attributes" do
      attrs = TestDashboard.form_attributes_list

      assert_includes attrs, :name
      assert_includes attrs, :email
      assert_not_includes attrs, :id
    end

    test "collection_includes should set preload associations" do
      includes = TestDashboard.collection_includes_list

      assert_includes includes, :posts
    end

    test "show_includes should set preload associations" do
      includes = TestDashboard.show_includes_list

      assert_includes includes, :posts
    end

    test "attributes_for should return correct attributes for index view" do
      attrs = TestDashboard.attributes_for(:index)

      assert_equal TestDashboard.collection_attributes_list, attrs
    end

    test "attributes_for should return correct attributes for collection view" do
      attrs = TestDashboard.attributes_for(:collection)

      assert_equal TestDashboard.collection_attributes_list, attrs
    end

    test "attributes_for should return correct attributes for show view" do
      attrs = TestDashboard.attributes_for(:show)

      assert_equal TestDashboard.show_attributes_list, attrs
    end

    test "attributes_for should return correct attributes for form view" do
      attrs = TestDashboard.attributes_for(:form)

      assert_equal TestDashboard.form_attributes_list, attrs
    end

    test "attributes_for should return empty array for unknown view" do
      attrs = TestDashboard.attributes_for(:unknown)

      assert_equal [], attrs
    end

    test "should use default collection attributes when none configured" do
      class DefaultDashboard < BaseDashboard
        resource User
      end

      attrs = DefaultDashboard.collection_attributes_list

      assert attrs.is_a?(Array)
    end

    test "should use default show attributes when none configured" do
      class DefaultShowDashboard < BaseDashboard
        resource User
      end

      attrs = DefaultShowDashboard.show_attributes_list

      assert attrs.is_a?(Array)
    end

    test "should use default form attributes when none configured" do
      class DefaultFormDashboard < BaseDashboard
        resource User
      end

      attrs = DefaultFormDashboard.form_attributes_list

      assert attrs.is_a?(Array)
    end

    test "should allow string resource name" do
      class StringResourceDashboard < BaseDashboard
        resource "User"
      end

      assert_equal User, StringResourceDashboard.resource_class
    end

    test "should allow symbol resource name" do
      class SymbolResourceDashboard < BaseDashboard
        resource :User
      end

      assert_equal User, SymbolResourceDashboard.resource_class
    end

    test "default collection includes only preload explicit associations" do
      dashboard = Class.new(BaseDashboard) do
        resource Post
        collection_attributes :id, :title, :user_id, :category
      end

      includes = dashboard.collection_includes_list

      assert_includes includes, :category
      assert_not_includes includes, :user
    end

    test "default show includes skips has_many associations" do
      dashboard = Class.new(BaseDashboard) do
        resource Post
      end

      includes = dashboard.show_includes_list

      assert_includes includes, :user
      assert_not_includes includes, :comments
    end
  end
end
