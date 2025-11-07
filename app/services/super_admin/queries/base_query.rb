# frozen_string_literal: true

module SuperAdmin
  module Queries
    # Abstract class for SuperAdmin query objects.
    # Provides common interface and shared utilities.
    class BaseQuery
      attr_reader :scope, :model_class

      # @param scope [ActiveRecord::Relation]
      # @param model_class [Class]
      def initialize(scope, model_class)
        @scope = scope
        @model_class = model_class
      end

      # Abstract method to implement in subclasses
      # @return [ActiveRecord::Relation]
      def call
        raise NotImplementedError, "#{self.class}#call must be implemented"
      end

      private

      # Returns the model's Arel table
      # @return [Arel::Table]
      def arel_table
        @arel_table ||= model_class.arel_table
      end

      # Returns the model's columns
      # @return [Array<ActiveRecord::ConnectionAdapters::Column>]
      def columns
        @columns ||= model_class.columns
      end

      # Returns columns of specified type
      # @param types [Array<Symbol>] Column types (e.g., [:string, :text])
      # @return [Array<ActiveRecord::ConnectionAdapters::Column>]
      def columns_of_type(*types)
        columns.select { |column| types.include?(column.type) }
      end
    end
  end
end
