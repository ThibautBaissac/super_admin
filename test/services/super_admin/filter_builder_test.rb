# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  class FilterBuilderTest < ActiveSupport::TestCase
    setup do
      @model = User
    end

    test "should build filter definitions for model" do
      definitions = FilterBuilder.definitions_for(@model)

      assert definitions.is_a?(Array)
      assert definitions.any?
      assert definitions.all? { |d| d.is_a?(FilterBuilder::FilterDefinition) }
    end

    test "should include filterable columns" do
      definitions = FilterBuilder.definitions_for(@model)

      # Should include string and enum columns
      filter_attributes = definitions.map(&:attribute)

      # Email should be filterable
      assert_includes filter_attributes, "email"
    end

    test "should include enum filters" do
      if @model.defined_enums.any?
        definitions = FilterBuilder.definitions_for(@model)

        enum_name = @model.defined_enums.keys.first
        filter_attributes = definitions.map(&:attribute)

        assert_includes filter_attributes, enum_name
      end
    end

    test "should exclude certain columns from filters" do
      definitions = FilterBuilder.definitions_for(@model)

      filter_attributes = definitions.map(&:attribute)

      # Should not include timestamps or id
      assert_not_includes filter_attributes, "id"
      assert_not_includes filter_attributes, "created_at"
      assert_not_includes filter_attributes, "updated_at"
    end

    test "should provide filter options for enums" do
      if @model.defined_enums.any?
        definitions = FilterBuilder.definitions_for(@model)

        enum_filter = definitions.find { |d| d.type == :enum }

        if enum_filter
          assert enum_filter.options.is_a?(Array)
          assert enum_filter.options.any?
        end
      end
    end

    test "should return permitted param keys" do
      param_keys = FilterBuilder.permitted_param_keys(@model)

      assert param_keys.is_a?(Array)
      assert param_keys.any?
      # Should include email_contains for string fields
      assert_includes param_keys, :email_contains
    end

    test "should apply filters to scope" do
      User.create!(email: "filter@example.com", name: "Filter Test")

      scope = User.all
      filtered = FilterBuilder.apply(scope, @model, { email_contains: "filter" })

      assert filtered.is_a?(ActiveRecord::Relation)
    end

    test "should handle empty filter params" do
      scope = User.all
      filtered = FilterBuilder.apply(scope, @model, {})

      assert_equal scope.count, filtered.count
    end

    test "should cache filter definitions" do
      # First call
      definitions1 = FilterBuilder.definitions_for(@model)

      # Second call should use cache
      definitions2 = FilterBuilder.definitions_for(@model)

      # Should be the same object from cache
      assert_equal definitions1, definitions2
    end

    test "should handle models without enums" do
      test_model = Class.new(ApplicationRecord) do
        self.table_name = "users"

        def self.name
          "SimpleModel"
        end
      end

      definitions = FilterBuilder.definitions_for(test_model)

      assert definitions.is_a?(Array)
    end

    test "should define param keys for string filters" do
      definitions = FilterBuilder.definitions_for(@model)
      email_filter = definitions.find { |d| d.attribute == "email" }

      if email_filter
        assert_includes email_filter.param_keys, :email_contains
      end
    end

    test "should define param keys for numeric filters" do
      # If User has numeric columns
      definitions = FilterBuilder.definitions_for(@model)
      numeric_filter = definitions.find { |d| d.type == :integer || d.type == :float }

      if numeric_filter
        attr = numeric_filter.attribute
        assert_includes numeric_filter.param_keys, :"#{attr}_min"
        assert_includes numeric_filter.param_keys, :"#{attr}_max"
      end
    end
  end
end
