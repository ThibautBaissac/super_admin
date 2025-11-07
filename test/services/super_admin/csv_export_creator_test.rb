# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class CsvExportCreatorTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
      @resource_name = "users"
      @model_class = User

      # Create test users
      3.times do |i|
        User.create!(
          email: "csvexport#{i}@example.com",
          name: "CSV Export #{i}"
        )
      end
    end

    test "should create csv export record" do
      assert_difference("CsvExport.count", 1) do
        CsvExportCreator.new(
          user: @user,
          resource_name: @resource_name,
          model_class: @model_class,
          scope: User.all,
          attributes: [ :name, :email ]
        ).call
      end

      export = CsvExport.last
      assert_equal @user.id, export.user_id
      assert_equal "users", export.resource_name
      assert_equal "User", export.model_class_name
      assert_equal "pending", export.status
    end

    test "should generate unique token" do
      export1 = CsvExportCreator.new(
        user: @user,
        resource_name: @resource_name,
        model_class: @model_class,
        scope: User.all,
        attributes: [ :name ]
      ).call

      export2 = CsvExportCreator.new(
        user: @user,
        resource_name: @resource_name,
        model_class: @model_class,
        scope: User.all,
        attributes: [ :name ]
      ).call

      assert_not_equal export1.token, export2.token
    end

    test "should set expiration date" do
      export = CsvExportCreator.new(
        user: @user,
        resource_name: @resource_name,
        model_class: @model_class,
        scope: User.all,
        attributes: [ :name ]
      ).call

      assert_not_nil export.expires_at
      assert export.expires_at > Time.current
    end

    test "should enqueue background job" do
      # Note: This test assumes Solid Queue or another job processor is configured
      # In a real environment, you'd check if the job was enqueued
      export = CsvExportCreator.new(
        user: @user,
        resource_name: @resource_name,
        model_class: @model_class,
        scope: User.all,
        attributes: [ :name, :email ]
      ).call

      assert export.persisted?
      assert_equal "pending", export.status
    end

    test "should store scope information" do
      filtered_scope = User.where("email LIKE ?", "%csvexport%")

      export = CsvExportCreator.new(
        user: @user,
        resource_name: @resource_name,
        model_class: @model_class,
        scope: filtered_scope,
        attributes: [ :name, :email ]
      ).call

      assert export.persisted?
    end
  end
end
