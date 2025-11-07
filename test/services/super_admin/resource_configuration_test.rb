# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class ResourceConfigurationTest < ActiveSupport::TestCase
    setup do
      @model = User
    end

    test "displayable_attributes prioritizes key fields and excludes sensitive ones" do
      attributes = SuperAdmin::ResourceConfiguration.displayable_attributes(@model)

      assert_equal %w[id email name], attributes.first(3)
      refute_includes attributes, "created_at"
      refute_includes attributes, "updated_at"
    end

    test "editable_attributes include nested attributes and exclude id" do
      attributes = SuperAdmin::ResourceConfiguration.editable_attributes(@model)

      assert_includes attributes, "posts_attributes"
      refute_includes attributes, "id"
      refute_includes attributes, "reset_password_token"
    end
  end
end
