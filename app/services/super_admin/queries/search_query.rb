# frozen_string_literal: true

module SuperAdmin
  module Queries
    # Query object for full-text search on string/text columns
    # and their belongs_to associations.
    class SearchQuery < BaseQuery
      attr_reader :term

      # @param scope [ActiveRecord::Relation]
      # @param model_or_term [Class, String, nil] Model class or legacy positional search term
      # @param term [String, nil] Search term when providing the model class explicitly
      def initialize(scope, model_or_term = nil, term: nil)
        if model_or_term.is_a?(Class)
          super(scope, model_or_term)
          @term = term
        else
          inferred_class = scope.respond_to?(:klass) ? scope.klass : model_or_term&.class
          super(scope, inferred_class)
          @term = model_or_term || term
        end
      end

      # Applies full-text search
      # @return [ActiveRecord::Relation]
      def call
        return scope if term.blank?

        sanitized_term = ActiveRecord::Base.sanitize_sql_like(term)
        original_pattern = "%#{sanitized_term}%"
        lower_pattern = "%#{sanitized_term.downcase}%"
        patterns = [ original_pattern ]
        patterns << lower_pattern unless lower_pattern == original_pattern

        predicates = []

        # Search in model columns
        base_predicates = search_in_columns(patterns, lower_pattern)
        predicates << base_predicates if base_predicates.present?

        # Search in belongs_to associations
        association_data = search_in_associations(patterns, lower_pattern)
        predicates.concat(association_data[:predicates]) if association_data[:predicates].present?

        return scope if predicates.empty?

        result = scope
        result = result.left_outer_joins(association_data[:associations]) if association_data[:associations].present?
        result.where(predicates.reduce { |memo, predicate| memo.or(predicate) })
      end

      private

      # Searches in model's string/text columns
      # @param patterns [Array<String>]
      # @param lower_pattern [String]
      # @return [Arel::Nodes::Node, nil]
      def search_in_columns(patterns, lower_pattern)
        searchable_columns = columns_of_type(:string, :text)
        return nil if searchable_columns.empty?

        column_predicates = searchable_columns.map do |column|
          build_column_predicates(column, patterns, lower_pattern)
        end

        column_predicates.reduce { |memo, predicate| memo.or(predicate) }
      end

      # Builds predicates for a given column
      # @param column [ActiveRecord::ConnectionAdapters::Column]
      # @param patterns [Array<String>]
      # @param lower_pattern [String]
      # @return [Arel::Nodes::Node]
      def build_column_predicates(column, patterns, lower_pattern)
        lowered_column = Arel::Nodes::NamedFunction.new("LOWER", [ arel_table[column.name] ])

        column_predicates = patterns.map do |pattern|
          arel_table[column.name].matches(Arel::Nodes.build_quoted(pattern))
        end

        column_predicates << lowered_column.matches(Arel::Nodes.build_quoted(lower_pattern))

        column_predicates.reduce { |memo, predicate| memo.or(predicate) }
      end

      # Searches in belongs_to associations
      # @param patterns [Array<String>]
      # @param lower_pattern [String]
      # @return [Hash] { predicates: Array, associations: Array }
      def search_in_associations(patterns, lower_pattern)
        return { predicates: [], associations: [] } unless model_class.respond_to?(:reflect_on_all_associations)

        associations = model_class.reflect_on_all_associations(:belongs_to).reject(&:polymorphic?)

        predicates = []
        joined_associations = []

        associations.each do |association|
          association_predicates = build_association_predicates(association, patterns, lower_pattern)
          next if association_predicates.nil?

          predicates << association_predicates
          joined_associations << association.name
        end

        { predicates: predicates, associations: joined_associations.uniq }
      end

      # Builds predicates for a given association
      # @param association [ActiveRecord::Reflection]
      # @param patterns [Array<String>]
      # @param lower_pattern [String]
      # @return [Arel::Nodes::Node, nil]
      def build_association_predicates(association, patterns, lower_pattern)
        begin
          associated_class = association.klass
        rescue NameError
          return nil
        end

        return nil unless associated_class.respond_to?(:columns)
        return nil unless associated_class.table_exists?

        associated_columns = associated_class.columns.select { |column| %i[string text].include?(column.type) }
        return nil if associated_columns.empty?

        association_table = associated_class.arel_table

        column_predicates = associated_columns.map do |column|
          attribute = association_table[column.name]
          lowered = Arel::Nodes::NamedFunction.new("LOWER", [ attribute ])

          predicates_for_column = patterns.map do |pattern|
            attribute.matches(Arel::Nodes.build_quoted(pattern))
          end

          predicates_for_column << lowered.matches(Arel::Nodes.build_quoted(lower_pattern))

          predicates_for_column.reduce { |memo, predicate| memo.or(predicate) }
        end

        column_predicates.reduce { |memo, predicate| memo.or(predicate) }
      end
    end
  end
end
