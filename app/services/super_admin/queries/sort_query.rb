# frozen_string_literal: true

module SuperAdmin
  module Queries
    # Query object for sorting on a given column.
    class SortQuery < BaseQuery
      attr_reader :sort_column, :direction

      # @param scope [ActiveRecord::Relation]
      # @param model_class [Class]
      # @param sort_column [String, nil] Sort column name
      # @param direction [String, nil] Direction (asc/desc)
      def initialize(scope, model_class, sort_column: nil, direction: nil)
        super(scope, model_class)
        @sort_column = sort_column
        @direction = direction
      end

      # Applies sorting
      # @return [ActiveRecord::Relation]
      def call
        return default_sort if sort_column.blank?

        column = model_class.columns_hash[sort_column.to_s]
        return default_sort unless column

        sanitized_direction = direction == "desc" ? :desc : :asc
        arel_column = arel_table[column.name]
        scope.order(arel_column.public_send(sanitized_direction))
      end

      private

      # Default sort by id descending
      # @return [ActiveRecord::Relation]
      def default_sort
        scope.order(id: :desc)
      end
    end
  end
end
