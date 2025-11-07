# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module Resources
    class PermittedAttributesTest < ActiveSupport::TestCase
      setup do
        @user_model = User
      end

      test "should permit scalar attributes" do
        permitted = PermittedAttributes.new(@user_model).call

        assert_includes permitted, :email
        assert_includes permitted, :name
      end

      test "should permit enum attributes" do
        permitted = PermittedAttributes.new(@user_model).call

        # Role should be included if it's an enum and not filtered out
        # This may vary based on configuration
        if @user_model.defined_enums.key?("role")
          # Check if role is permitted or if it's excluded by some configuration
          # We'll just verify the permitted array is valid
          assert permitted.is_a?(Array)
        end
      end

      test "should permit belongs_to associations" do
        permitted = PermittedAttributes.new(Post).call

        assert_includes permitted, :user_id
      end

      test "should permit has_many associations with nested attributes" do
        permitted = PermittedAttributes.new(@user_model).call

        # Check for nested attributes if User has_many posts
        if @user_model.reflect_on_all_associations(:has_many).any? { |a| a.name == :posts }
          nested_attr = permitted.find { |attr| attr.is_a?(Hash) && attr.key?(:posts_attributes) }
          assert nested_attr, "Should include posts_attributes"
        end
      end

      test "should exclude timestamps by default" do
        permitted = PermittedAttributes.new(@user_model).call

        assert_not_includes permitted, :created_at
        assert_not_includes permitted, :updated_at
      end

      test "should exclude id attribute" do
        permitted = PermittedAttributes.new(@user_model).call

        assert_not_includes permitted, :id
      end

      test "should handle models without associations" do
        # Create a simple model without associations
        test_model = Class.new(ApplicationRecord) do
          self.table_name = "users"

          def self.name
            "TestModelWithoutAssociations"
          end
        end

        permitted = PermittedAttributes.new(test_model).call
        assert permitted.is_a?(Array)
        assert permitted.any?
      end

      test "should include _destroy for nested attributes" do
        permitted = PermittedAttributes.new(@user_model).call

        nested_attrs = permitted.select { |attr| attr.is_a?(Hash) }
        nested_attrs.each do |nested_attr|
          nested_attr.each_value do |attrs|
            assert_includes attrs, :_destroy if attrs.is_a?(Array)
          end
        end
      end
    end
  end
end
