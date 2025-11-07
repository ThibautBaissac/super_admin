# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class FormBuilderTest < ActiveSupport::TestCase
    setup do
      @view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
      @user = User.new
      @form = ActionView::Helpers::FormBuilder.new(:user, @user, @view, {})
    end

    test "should build field for attribute" do
      builder = FormBuilder.new(model_class: User, form: @form, attribute_name: :name)

      assert_equal :name, builder.attribute_name.to_sym
      assert_equal User, builder.model_class
    end

    test "should detect field type from column" do
      builder = FormBuilder.new(model_class: User, form: @form, attribute_name: :name)
      field_html = builder.build_field

      assert field_html.is_a?(String)
      assert field_html.length > 0
    end

    test "should return field type" do
      builder = FormBuilder.new(model_class: User, form: @form, attribute_name: :name)
      type = builder.field_type

      assert type.is_a?(Symbol)
    end

    test "should return field label" do
      builder = FormBuilder.new(model_class: User, form: @form, attribute_name: :name)
      label = builder.field_label

      assert label.is_a?(String)
      assert_equal "Name", label
    end

    test "should handle email field" do
      builder = FormBuilder.new(model_class: User, form: @form, attribute_name: :email)
      field_html = builder.build_field

      assert field_html.is_a?(String)
    end

    test "should handle datetime field" do
      builder = FormBuilder.new(model_class: User, form: @form, attribute_name: :created_at)
      field_html = builder.build_field

      assert field_html.is_a?(String)
    end

    test "should handle enum field" do
      if User.defined_enums.any?
        enum_name = User.defined_enums.keys.first
        builder = FormBuilder.new(model_class: User, form: @form, attribute_name: enum_name)
        field_html = builder.build_field

        assert field_html.is_a?(String)
      end
    end

    test "should handle association field" do
      builder = FormBuilder.new(model_class: Post, form: @form, attribute_name: :user_id)
      field_html = builder.build_field

      assert field_html.is_a?(String)
    end

    test "should provide field options" do
      builder = FormBuilder.new(model_class: User, form: @form, attribute_name: :name)
      options = builder.field_options

      assert options.is_a?(Hash)
    end
  end
end
