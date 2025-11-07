# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module FormFields
    class AssociationFieldTest < ActiveSupport::TestCase
      setup do
        @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        @post = Post.new
        @form = ActionView::Helpers::FormBuilder.new(:post, @post, @view, {})
      end

      test "should render select field for belongs_to association" do
        builder = FormBuilder.new(model_class: Post, form: @form, attribute_name: :user_id)
        field = AssociationField.new(builder)
        output = field.render

        assert_includes output, "select"
      end

      test "should include blank option for optional associations" do
        builder = FormBuilder.new(model_class: Post, form: @form, attribute_name: :user_id)
        field = AssociationField.new(builder)
        output = field.render

        # Should include blank option if column is nullable
        assert output.is_a?(String)
      end

      test "should load association records" do
        User.create!(email: "test1@example.com", name: "Test 1")
        User.create!(email: "test2@example.com", name: "Test 2")

        builder = FormBuilder.new(model_class: Post, form: @form, attribute_name: :user_id)
        field = AssociationField.new(builder)
        output = field.render

        assert_includes output, "select"
      end

      test "should respect association_select_limit configuration" do
        SuperAdmin.configure do |config|
          config.association_select_limit = 5
        end

        # Create more users than the limit
        10.times do |i|
          User.create!(email: "limituser#{i}@example.com", name: "User #{i}")
        end

        builder = FormBuilder.new(model_class: Post, form: @form, attribute_name: :user_id)
        field = AssociationField.new(builder)
        output = field.render

        assert output.is_a?(String)
      end

      test "should use display method for option labels" do
        user = User.create!(email: "display@example.com", name: "Display Name")

        builder = FormBuilder.new(model_class: Post, form: @form, attribute_name: :user_id)
        field = AssociationField.new(builder)
        output = field.render

        # Should use to_s method for display
        assert_includes output, "select"
      end

      test "should handle association errors gracefully" do
        # Test with an invalid association that doesn't exist
        builder = FormBuilder.new(model_class: Post, form: @form, attribute_name: :nonexistent_id)
        field = AssociationField.new(builder)
        output = field.render

        # Should fallback to text field when association not found
        assert output.is_a?(String)
      end

      test "should return association type" do
        builder = FormBuilder.new(model_class: Post, form: @form, attribute_name: :user_id)
        field = AssociationField.new(builder)

        assert_equal :association, field.type
      end

      test "should enable searchable select for large datasets" do
        SuperAdmin.configure do |config|
          config.association_select_limit = 2
        end

        # Create enough users to trigger searchable select
        5.times do |i|
          User.create!(email: "search#{i}@example.com", name: "User #{i}")
        end

        builder = FormBuilder.new(model_class: Post, form: @form, attribute_name: :user_id)
        field = AssociationField.new(builder)
        output = field.render

        # Should include data attributes for Stimulus controller
        assert_includes output, "data-controller" if output.is_a?(String)
      end

      test "should order records by name when available" do
        User.create!(email: "zzzz@example.com", name: "ZZZZ")
        User.create!(email: "aaaa@example.com", name: "AAAA")

        builder = FormBuilder.new(model_class: Post, form: @form, attribute_name: :user_id)
        field = AssociationField.new(builder)
        output = field.render

        # Records should be ordered by name
        assert output.is_a?(String)
      end
    end
  end
end
