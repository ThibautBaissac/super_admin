# frozen_string_literal: true

require "test_helper"

module SuperAdmin
  module Resources
    class ValueNormalizerTest < ActiveSupport::TestCase
      ColumnStub = Struct.new(:name, :type, :array) do
        def array?
          array
        end
      end

      class NestedModelStub
        def self.columns_hash
          { "labels" => ColumnStub.new("labels", :string, true) }
        end

        def self.reflect_on_association(_name)
          nil
        end
      end

      class ModelStub
        def self.columns_hash
          {
            "tags" => ColumnStub.new("tags", :string, true),
            "scores" => ColumnStub.new("scores", :integer, true),
            "title" => ColumnStub.new("title", :string, false)
          }
        end

        def self.reflect_on_association(name)
          return AssociationStub.new(NestedModelStub) if name.to_s == "details"

          nil
        end
      end

      class AssociationStub
        attr_reader :klass

        def initialize(klass)
          @klass = klass
        end
      end

      test "normalizes comma separated strings into arrays" do
        params = ActionController::Parameters.new(tags: "alpha, beta , gamma").permit!
        normalized = ValueNormalizer.new(ModelStub, params).normalize

        assert_equal %w[alpha beta gamma], normalized[:tags]
      end

      test "normalizes newline separated strings into arrays" do
        params = ActionController::Parameters.new(tags: "alpha\nbeta\n\ngamma").permit!
        normalized = ValueNormalizer.new(ModelStub, params).normalize

        assert_equal %w[alpha beta gamma], normalized[:tags]
      end

      test "normalizes nested attributes" do
        params = ActionController::Parameters.new(
          details_attributes: [
            ActionController::Parameters.new(labels: "first, second").permit!
          ]
        ).permit!

        ValueNormalizer.new(ModelStub, params).normalize
        nested = params[:details_attributes].first

        assert_equal %w[first second], nested[:labels]
      end

      test "casts numeric elements when possible" do
        params = ActionController::Parameters.new(scores: "1, 2, invalid").permit!
        normalized = ValueNormalizer.new(ModelStub, params).normalize

        assert_equal [ 1, 2, "invalid" ], normalized[:scores]
      end

      test "returns empty array for blank input" do
        params = ActionController::Parameters.new(tags: "  , \n ").permit!
        normalized = ValueNormalizer.new(ModelStub, params).normalize

        assert_equal [], normalized[:tags]
      end

      test "leaves untouched when params are not permitted" do
        params = ActionController::Parameters.new(tags: "alpha, beta")
        normalized = ValueNormalizer.new(ModelStub, params).normalize

        assert_equal params, normalized
        assert_equal "alpha, beta", params[:tags]
      end
    end
  end
end
