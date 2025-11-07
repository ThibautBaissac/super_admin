# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class ResourceExporterTest < ActiveSupport::TestCase
    setup do
      User.delete_all
      Post.delete_all

      @users = [
        User.create!(email: "export1@example.com", name: "Export 1"),
        User.create!(email: "export2@example.com", name: "Export 2"),
        User.create!(email: "export3@example.com", name: "Export 3")
      ]

      @scope = User.where(id: @users.map(&:id))
    end

    test "should export to CSV format" do
      exporter = ResourceExporter.new(User, @scope, attributes: [ :name, :email ])
      csv_data = exporter.to_csv

      assert csv_data.is_a?(String)
      assert_includes csv_data, "Name"
      assert_includes csv_data, "Email"
      assert_includes csv_data, "export1@example.com"
    end

    test "should include headers in CSV" do
      exporter = ResourceExporter.new(User, @scope, attributes: [ :name, :email ])
      csv_data = exporter.to_csv

      lines = csv_data.split("\n")
      headers = lines.first

      assert_includes headers, "Name"
      assert_includes headers, "Email"
    end

    test "should export all specified attributes" do
      exporter = ResourceExporter.new(User, @scope, attributes: [ :id, :name, :email ])
      csv_data = exporter.to_csv

      assert_includes csv_data, "Id"
      assert_includes csv_data, "Name"
      assert_includes csv_data, "Email"
    end

    test "should export all records in scope" do
      exporter = ResourceExporter.new(User, @scope, attributes: [ :name ])
      csv_data = exporter.to_csv

      lines = csv_data.split("\n")
      # Header + 3 records
      assert_equal 4, lines.length
    end

    test "should handle empty scope" do
      empty_scope = User.where(id: nil)
      exporter = ResourceExporter.new(User, empty_scope, attributes: [ :name, :email ])
      csv_data = exporter.to_csv

      lines = csv_data.split("\n")
      # Should only have header
      assert_equal 1, lines.length
    end

    test "should handle special characters in data" do
      User.create!(
        email: "special@example.com",
        name: 'Name with "quotes" and, commas'
      )

      scope = User.where(email: "special@example.com")
      exporter = ResourceExporter.new(User, scope, attributes: [ :name, :email ])
      csv_data = exporter.to_csv

      # CSV should properly escape special characters
      assert_includes csv_data, "special@example.com"
    end

    test "should handle associations" do
      user = @users.first
    Post.create!(title: "Test Post", body: "Sample body content", user: user)

      scope = Post.where(user: user)
      exporter = ResourceExporter.new(Post, scope, attributes: [ :title, :user_id ])
      csv_data = exporter.to_csv

      assert_includes csv_data, "Title"
      assert_includes csv_data, "Test Post"
    end

    test "should format datetime fields" do
      exporter = ResourceExporter.new(User, @scope, attributes: [ :name, :created_at ])
      csv_data = exporter.to_csv

      assert_includes csv_data, "Created at"
      # Should include some datetime value in ISO8601 format
      assert csv_data.length > 50
    end

    test "should use all attributes when none specified" do
      exporter = ResourceExporter.new(User, @scope)
      csv_data = exporter.to_csv

      # Should include all User attributes
      assert_includes csv_data, "Email"
      assert_includes csv_data, "Name"
    end
  end
end
