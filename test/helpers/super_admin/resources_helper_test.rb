# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class ResourcesHelperTest < ActionView::TestCase
    setup do
      @user = User.create!(email: "helper@example.com", name: "Helper Test")
    end

    test "should display attribute value" do
      value = display_attribute(@user, :name)

      assert_equal "Helper Test", value
    end

    test "should display email attribute" do
      value = display_attribute(@user, :email)

      assert_equal "helper@example.com", value
    end

    test "should format datetime attributes" do
      value = display_attribute(@user, :created_at)

      # Should format as a readable datetime
      assert value.is_a?(String)
      assert value.length > 0
    end

    test "should handle nil values" do
      @user.name = nil
      value = display_attribute(@user, :name)

      assert_equal "", value
    end

    test "should display boolean values" do
      # If User has a boolean attribute
      column = User.columns.find { |c| c.type == :boolean }
      if column
        value = display_attribute(@user, column.name.to_sym)

        assert [ "Yes", "No", "" ].include?(value)
      end
    end

    test "should display association names" do
      post = Post.create!(title: "Test Post", body: "Test body content", user: @user)

      value = display_attribute(post, :user)

      # Should display user's name or email
      assert value.is_a?(String)
      assert value.length > 0
    end

    test "should humanize attribute names" do
      name = humanize_attribute(:created_at)

      assert_equal "Created at", name
    end

    test "should handle enum values" do
      if User.defined_enums.any?
        enum_name = User.defined_enums.keys.first
        @user.send("#{enum_name}=", User.send(enum_name.pluralize).keys.first)

        value = display_attribute(@user, enum_name.to_sym)

        # Should display humanized enum value
        assert value.is_a?(String)
      end
    end

    test "format_attribute_value should format nil values" do
      @user.name = nil
      result = format_attribute_value(@user, :name)

      assert_match(/—/, result)
    end

    test "format_attribute_value should format true values" do
      @user.stub :active, true do
        result = format_attribute_value(@user, :active)

        assert_match(/✓/, result)
      end
    end

    test "format_attribute_value should format false values" do
      @user.stub :active, false do
        result = format_attribute_value(@user, :active)

        assert_match(/✗/, result)
      end
    end

    test "format_attribute_value should format Date values" do
      date = Date.new(2023, 1, 15)
      @user.stub :created_at, date do
        result = format_attribute_value(@user, :created_at)

        assert result.is_a?(String)
        assert result.length > 0
      end
    end

    test "format_attribute_value should format Time values" do
      time = Time.new(2023, 1, 15, 12, 30, 0)
      @user.stub :updated_at, time do
        result = format_attribute_value(@user, :updated_at)

        assert result.is_a?(String)
        assert result.length > 0
      end
    end

    test "format_attribute_value should format Integer values with delimiter" do
      @user.stub :id, 1000000 do
        result = format_attribute_value(@user, :id)

        assert result.is_a?(String)
      end
    end

    test "format_attribute_value should format Float values with precision" do
      value_mock = 4.567
      @user.define_singleton_method(:rating) { value_mock }
      result = format_attribute_value(@user, :rating)

      assert result.is_a?(String)
    end

    test "format_attribute_value should handle empty strings" do
      @user.name = ""
      result = format_attribute_value(@user, :name)

      assert_match(/empty/i, result) || assert_match(/—/, result)
    end

    test "format_attribute_value should handle non-empty strings" do
      @user.name = "Test User"
      result = format_attribute_value(@user, :name)

      assert_equal "Test User", result
    end

    test "display_association_value should handle collection associations" do
      post = Post.create!(title: "Test Post", body: "Test body content", user: @user)

      # Test collection association if it exists
      if post.respond_to?(:comments) && post.class.reflect_on_association(:comments)
        reflection = post.class.reflect_on_association(:comments)
        result = send(:display_association_value, post.comments, reflection)

        assert result.is_a?(String)
      end
    end

    test "association_display_name should try multiple methods" do
      result = send(:association_display_name, @user)

      assert result.is_a?(String)
      assert result.length > 0
    end

    test "humanize_enum_value_should_format_enum_values" do
      if User.defined_enums.key?("role")
        @user.role = "admin"
        result = send(:humanize_enum_value, @user, "role", "admin")

        assert result.is_a?(String)
        assert result.length > 0
      end
    end

    test "badge_class_for returns correct class for true value" do
      result = badge_class_for(true)

      assert_equal "bg-green-100 text-green-800", result
    end

    test "badge_class_for returns correct class for false value" do
      result = badge_class_for(false)

      assert_equal "bg-red-100 text-red-800", result
    end

    test "badge_class_for returns correct class for nil value" do
      result = badge_class_for(nil)

      assert_equal "bg-gray-100 text-gray-800", result
    end

    test "badge_class_for returns default class for other values" do
      result = badge_class_for("some string")

      assert_equal "bg-blue-100 text-blue-800", result
    end

    test "humanize_model_name returns humanized model name" do
      result = humanize_model_name(User)

      assert result.is_a?(String)
      assert result.length > 0
    end

    test "sort_params_for returns correct params for new sort" do
      result = sort_params_for("name", current_sort: "email", current_direction: "asc")

      assert_equal({ sort: "name", direction: "asc" }, result)
    end

    test "sort_params_for reverses direction for current sort" do
      result = sort_params_for("name", current_sort: "name", current_direction: "asc")

      assert_equal({ sort: "name", direction: "desc" }, result)
    end

    test "sort_indicator_for returns nil for non-current sort" do
      result = sort_indicator_for("name", current_sort: "email", current_direction: "asc")

      assert_nil result
    end

    test "sort_indicator_for returns up arrow for asc sort" do
      result = sort_indicator_for("name", current_sort: "name", current_direction: "asc")

      assert_equal "↑", result
    end

    test "sort_indicator_for returns down arrow for desc sort" do
      result = sort_indicator_for("name", current_sort: "name", current_direction: "desc")

      assert_equal "↓", result
    end

    test "filter_value returns empty string when no filters" do
      result = filter_value(nil, :status)

      assert_equal "", result
    end

    test "filter_value returns filter value from hash" do
      filters = { status: "active", "role" => "admin" }

      assert_equal "active", filter_value(filters, :status)
      assert_equal "admin", filter_value(filters, :role)
    end

    test "icon_for_column_type returns SVG for string type" do
      result = icon_for_column_type(:string)

      assert_match(/<svg/, result)
    end

    test "icon_for_column_type returns SVG for boolean type" do
      result = icon_for_column_type(:boolean)

      assert_match(/<svg/, result)
    end
  end
end
