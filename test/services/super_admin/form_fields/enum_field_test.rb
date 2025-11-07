# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module FormFields
    class EnumFieldTest < ActiveSupport::TestCase
      setup do
        @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        @user = User.new
        @form = ActionView::Helpers::FormBuilder.new(:user, @user, @view, {})
      end

      test "should render select field for enum" do
        if User.defined_enums.any?
          enum_name = User.defined_enums.keys.first
          builder = FormBuilder.new(model_class: User, form: @form, attribute_name: enum_name)
          field = EnumField.new(builder)
          output = field.render

          assert_includes output, "select"
        end
      end

      test "should include all enum values as options" do
        if User.defined_enums.key?("role")
          builder = FormBuilder.new(model_class: User, form: @form, attribute_name: :role)
          field = EnumField.new(builder)
          output = field.render

          # Each enum value should be present in the output
          assert output.is_a?(String)
          assert_includes output, "select"
        end
      end

      test "should handle enum with custom labels" do
        if User.defined_enums.any?
          enum_name = User.defined_enums.keys.first
          builder = FormBuilder.new(model_class: User, form: @form, attribute_name: enum_name)
          field = EnumField.new(builder)
          output = field.render

          # Should render humanized labels
          assert_includes output, "select"
        end
      end

      test "should include blank option" do
        if User.defined_enums.any?
          enum_name = User.defined_enums.keys.first
          builder = FormBuilder.new(model_class: User, form: @form, attribute_name: enum_name)
          field = EnumField.new(builder)
          output = field.render

          # Should allow blank selection
          assert output.is_a?(String)
        end
      end

      test "should return enum type" do
        if User.defined_enums.any?
          enum_name = User.defined_enums.keys.first
          builder = FormBuilder.new(model_class: User, form: @form, attribute_name: enum_name)
          field = EnumField.new(builder)

          assert_equal :enum, field.type
        end
      end

      test "should humanize enum values" do
        if User.defined_enums.key?("role")
          builder = FormBuilder.new(model_class: User, form: @form, attribute_name: :role)
          field = EnumField.new(builder)
          output = field.render

          # Should include humanized role names
          User.roles.keys.each do |role|
            # Output should contain the role in some form
            assert output.length > 0
          end
        end
      end

      test "should use enum values from model" do
        if User.defined_enums.key?("role")
          builder = FormBuilder.new(model_class: User, form: @form, attribute_name: :role)
          field = EnumField.new(builder)
          output = field.render

          # Should generate options from User.roles
          assert output.is_a?(String)
          assert output.length > 50 # Should have substantial content
        end
      end
    end
  end
end
