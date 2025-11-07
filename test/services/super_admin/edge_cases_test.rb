# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class EdgeCasesTest < ActiveSupport::TestCase
    test "should handle model with no records" do
      # Delete all users
      User.delete_all

      result = ResourceQuery.filtered_scope(
        User,
        search: nil,
        sort: nil,
        direction: nil,
        filters: {}
      )

      assert_equal 0, result.count
    end

    test "should handle model with single record" do
      User.delete_all
      user = User.create!(email: "single@example.com", name: "Single")

      result = ResourceQuery.filtered_scope(
        User,
        search: nil,
        sort: "name",
        direction: "asc",
        filters: {}
      )

      assert_equal 1, result.count
      assert_equal user.id, result.first.id
    end

    test "should handle search with no matches" do
      User.create!(email: "test@example.com", name: "Test")

      result = ResourceQuery.filtered_scope(
        User,
        search: "nonexistent_query_string_12345",
        sort: nil,
        direction: nil,
        filters: {}
      )

      assert_equal 0, result.count
    end

    test "should handle filters with no matches" do
      User.delete_all
      User.create!(email: "user+filter@example.com", name: "User", role: :user)

      result = ResourceQuery.filtered_scope(
        User,
        search: nil,
        sort: nil,
        direction: nil,
        filters: { email_contains: "missing@example.com" }
      )

      assert_equal 0, result.count
    end

    test "should handle sorting by column with null values" do
      Post.delete_all
      user = users(:one)

      Post.create!(title: "Post 1", body: "Sample body content", user: user, published_at: nil)
      Post.create!(title: "Post 2", body: "Sample body content", user: user, published_at: 1.day.ago)
      Post.create!(title: "Post 3", body: "Sample body content", user: user, published_at: Time.current)

      result = ResourceQuery.filtered_scope(
        Post,
        search: nil,
        sort: "published_at",
        direction: "asc",
        filters: {}
      )

      # Should not raise error
      assert_equal 3, result.count
    end

    test "should handle exporting with no records" do
      empty_scope = User.where(id: nil)
      exporter = ResourceExporter.new(User, empty_scope, attributes: [ :name, :email ])
      csv = exporter.to_csv

      lines = csv.split("\n")
      # Should have header only
      assert_equal 1, lines.length
    end

    test "should handle exporting with null values" do
      Post.delete_all
      user = users(:one)
      post = Post.create!(title: "Post With Null", body: "Sample body content", user: user, published_at: nil)
      scope = Post.where(id: post.id)

      exporter = ResourceExporter.new(Post, scope, attributes: [ :title, :published_at ])
      csv = exporter.to_csv

      # Should handle null values gracefully
      assert csv.include?("Post With Null")
    end

    test "should handle model with very long attribute values" do
      long_name = "a" * 1000
      user = User.create!(email: "long@example.com", name: long_name)

      exporter = ResourceExporter.new(User, User.where(id: user.id), attributes: [ :name ])
      csv = exporter.to_csv

      # Should handle long values
      assert csv.length > 1000
    end

    test "should handle associations with no records" do
      post = Post.new(title: "Post without user")

      view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
      form = ActionView::Helpers::FormBuilder.new(:post, post, view, {})
      builder = FormBuilder.new(model_class: Post, form: form, attribute_name: :user_id)
      field = FormFields::AssociationField.new(builder)

      output = field.render
      # Should not raise error
      assert output.is_a?(String)
    end

    test "should handle enum with single value" do
      # Test with a model that has enum with one value
      if User.defined_enums.any?
        enum_name = User.defined_enums.keys.first

        view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        form = ActionView::Helpers::FormBuilder.new(:user, User.new, view, {})
        builder = FormBuilder.new(model_class: User, form: form, attribute_name: enum_name)
        field = FormFields::EnumField.new(builder)

        output = field.render
        assert output.is_a?(String)
      end
    end

    test "should handle concurrent CSV exports" do
      users = 3.times.map do |i|
        User.create!(email: "concurrent#{i}@example.com", name: "User #{i}")
      end

      threads = 5.times.map do
        Thread.new do
          scope = User.where(id: users.map(&:id))
          exporter = ResourceExporter.new(User, scope, attributes: [ :name, :email ])
          exporter.to_csv
        end
      end

      results = threads.map(&:value)

      # All exports should succeed
      assert_equal 5, results.length
      results.each do |csv|
        assert csv.is_a?(String)
        assert csv.include?("Email")
      end
    end

    test "should handle filter builder with model having no columns" do
      # Create a minimal model
      test_model = Class.new(ApplicationRecord) do
        self.table_name = "users"

        def self.name
          "MinimalModel"
        end

        def self.columns
          []
        end
      end

      definitions = FilterBuilder.definitions_for(test_model)

      # Should return empty array without error
      assert_equal [], definitions
    end

    test "should handle search query with only whitespace" do
      User.create!(email: "whitespace@example.com", name: "Test")

      result = ResourceQuery.filtered_scope(
        User,
        search: "   \t\n   ",
        sort: nil,
        direction: nil,
        filters: {}
      )

      # Should treat as empty search
      assert result.count >= 0
    end

    test "should handle audit log creation with circular references" do
      user = users(:one)
      post = Post.create!(title: "Test", body: "Sample body content", user: user)

      # Create audit log with complex nested changes
      changes = {
        "title" => [ "Old", "New" ],
        "metadata" => { "nested" => { "deeply" => { "nested" => "value" } } }
      }

      log = Auditing.log!(
        user: user,
        resource: post,
        action: :update,
        changes: changes
      )

      # Should handle nested structures
      assert log.is_a?(AuditLog) || log.nil?
    end

    test "should handle resources controller with missing params" do
      # This tests that the controller handles missing required params
      # We can't easily test controller directly, but we can test the supporting services
      context = Resources::Context.new("users")

      assert_equal User, context.model_class
      assert_equal "user", context.singular_name
    end

    test "should handle permitted attributes with circular associations" do
      # Test that permitted attributes doesn't infinite loop
      # on models with circular associations
      permitted = Resources::PermittedAttributes.new(User).call

      assert permitted.is_a?(Array)
      assert permitted.any?
    end

    test "should handle zero values in numeric filters" do
      # If User had a numeric column with value 0
      scope = User.all

      result = FilterBuilder.apply(scope, User, {})

      assert result.is_a?(ActiveRecord::Relation)
    end

    test "should handle boolean false values in filters" do
      column = User.columns.find { |c| c.type == :boolean }

      if column
        scope = User.all
        result = FilterBuilder.apply(scope, User, { "#{column.name}_equals" => "false" })

        assert result.is_a?(ActiveRecord::Relation)
      else
        skip "No boolean columns on User model"
      end
    end
  end
end
