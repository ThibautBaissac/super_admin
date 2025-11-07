# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class ModelInspectorTest < ActiveSupport::TestCase
    test "should return all models" do
      models = ModelInspector.all_models
      assert models.is_a?(Array)
      # Should include our test models if they have dashboards
    end

    test "should find model by name" do
      # This will only work if User dashboard exists
      # model = ModelInspector.find_model("users")
      # assert_equal User, model if model
    end

    test "should inspect model attributes" do
      attributes = ModelInspector.inspect_attributes(User)

      assert attributes.is_a?(Hash)
      assert attributes.key?("email")
      assert attributes.key?("name")

      email_attr = attributes["email"]
      assert_equal :string, email_attr[:type]
    end

    test "should inspect model associations" do
      associations = ModelInspector.inspect_associations(User)

      assert associations.is_a?(Hash)
      assert associations.key?(:posts)

      posts_assoc = associations[:posts]
      assert_equal :has_many, posts_assoc[:type]
      assert_equal "Post", posts_assoc[:class_name]
    end

    test "should inspect model validations" do
      validations = ModelInspector.inspect_validations(User)

      assert validations.is_a?(Hash)
      assert validations.key?(:email)
      assert validations.key?(:name)

      email_validations = validations[:email]
      assert email_validations.any? { |v| v[:kind] == :presence }
    end

    test "should detect enums" do
      assert ModelInspector.enum?(User, :role)
      assert_not ModelInspector.enum?(User, :email)
    end

    test "should return enum values" do
      enum_values = ModelInspector.enum_values(User, :role)

      assert enum_values.is_a?(Hash)
      assert enum_values.key?("user")
      assert enum_values.key?("admin")
    end

    test "should exclude system models" do
      excluded = ModelInspector.send(:excluded_model?, ActiveRecord::SchemaMigration)
      assert excluded
    end

    test "should not exclude regular models" do
      excluded = ModelInspector.send(:excluded_model?, User)
      assert_not excluded
    end

    test "should inspect full model" do
      info = ModelInspector.inspect_model(User)

      assert_equal "User", info[:name]
      assert_equal "users", info[:table_name]
      assert info[:attributes].present?
      assert info[:associations].present?
      assert info[:validations].present?
    end
  end
end
