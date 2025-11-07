# frozen_string_literal: true

require "bigdecimal"

module SuperAdmin
  module Queries
    # Query object for applying typed filters (string, numeric, date, boolean, enum).
    class FilterQuery < BaseQuery
      STRING_TYPES = %i[string text].freeze
      NUMERIC_TYPES = %i[integer float decimal].freeze
      DATE_TYPES = %i[date datetime].freeze
      BOOLEAN_TYPES = %i[boolean].freeze

      attr_reader :filters, :filter_definitions

      # @param scope [ActiveRecord::Relation]
      # @param model_class [Class]
      # @param filters [Hash] Paramètres de filtrage
      # @param filter_definitions [Array<SuperAdmin::FilterBuilder::FilterDefinition>]
      def initialize(scope, model_class, filters = nil, filter_definitions: nil, **kwargs)
        super(scope, model_class)

        provided_filters = if filters.is_a?(Hash) && !kwargs.key?(:filters)
          filters
        else
          kwargs[:filters] || {}
        end

        provided_definitions = filter_definitions || kwargs[:filter_definitions]

        @filters = provided_filters.to_h.stringify_keys
        @filter_definitions = provided_definitions || SuperAdmin::FilterBuilder.definitions_for(model_class)
      end

      # Applies all filters
      # @return [ActiveRecord::Relation]
      def call
        return scope if filters.blank?

        filter_definitions.each do |definition|
          apply_filter_for_definition(definition)
        end

        scope
      end

      private

      # Applies filter based on its definition
      # @param definition [SuperAdmin::FilterBuilder::FilterDefinition]
      def apply_filter_for_definition(definition)
        case definition.type
        when *STRING_TYPES
          apply_string_filter(definition)
        when *NUMERIC_TYPES
          apply_numeric_filter(definition)
        when *DATE_TYPES
          apply_date_filter(definition)
        when *BOOLEAN_TYPES
          apply_boolean_filter(definition)
        when :enum
          apply_enum_filter(definition)
        end
      end

      # Applies string filter (contains)
      # @param definition [SuperAdmin::FilterBuilder::FilterDefinition]
      def apply_string_filter(definition)
        key = "#{definition.attribute}_contains"
        value = filters[key]
        return if value.blank?

        column = column_for(definition.attribute)
        return unless column && STRING_TYPES.include?(column.type)

        sanitized = ActiveRecord::Base.sanitize_sql_like(value)
        term = "%#{sanitized.downcase}%"
        lowered_column = Arel::Nodes::NamedFunction.new("LOWER", [ arel_table[definition.attribute] ])
        @scope = scope.where(lowered_column.matches(Arel::Nodes.build_quoted(term)))
      end

      # Applies numeric filter (min/max)
      # @param definition [SuperAdmin::FilterBuilder::FilterDefinition]
      def apply_numeric_filter(definition)
        min_key = "#{definition.attribute}_min"
        max_key = "#{definition.attribute}_max"

        if filters[min_key].present?
          parsed_min = parse_numeric(filters[min_key], definition.type)
          @scope = scope.where(arel_table[definition.attribute].gteq(parsed_min)) if parsed_min
        end

        if filters[max_key].present?
          parsed_max = parse_numeric(filters[max_key], definition.type)
          @scope = scope.where(arel_table[definition.attribute].lteq(parsed_max)) if parsed_max
        end
      end

      # Applies date filter (from/to)
      # @param definition [SuperAdmin::FilterBuilder::FilterDefinition]
      def apply_date_filter(definition)
        from_key = "#{definition.attribute}_from"
        to_key = "#{definition.attribute}_to"

        if filters[from_key].present?
          parsed_from = parse_temporal(filters[from_key], definition.type)
          @scope = scope.where(arel_table[definition.attribute].gteq(parsed_from)) if parsed_from
        end

        if filters[to_key].present?
          parsed_to = parse_temporal(filters[to_key], definition.type)
          @scope = scope.where(arel_table[definition.attribute].lteq(parsed_to)) if parsed_to
        end
      end

      # Applies boolean filter (equals)
      # @param definition [SuperAdmin::FilterBuilder::FilterDefinition]
      def apply_boolean_filter(definition)
        key = "#{definition.attribute}_equals"
        return unless filters.key?(key)

        parsed = parse_boolean(filters[key])
        @scope = scope.where(definition.attribute => parsed) unless parsed.nil?
      end

      # Applies enum filter (equals)
      # @param definition [SuperAdmin::FilterBuilder::FilterDefinition]
      def apply_enum_filter(definition)
        key = "#{definition.attribute}_equals"
        value = filters[key]
        return if value.blank?
        return unless definition.options.include?(value)

        @scope = scope.where(definition.attribute => value)
      end

      # Parses numeric value based on type
      # @param value [String]
      # @param type [Symbol]
      # @return [Numeric, nil]
      def parse_numeric(value, type)
        case type
        when :integer
          Integer(value)
        when :float
          Float(value)
        when :decimal
          BigDecimal(value)
        end
      rescue ArgumentError, TypeError
        nil
      end

      # Parses temporal value based on type
      # @param value [String]
      # @param type [Symbol]
      # @return [Date, Time, nil]
      def parse_temporal(value, type)
        case type
        when :date
          Date.parse(value)
        when :datetime
          Time.zone.parse(value)
        end
      rescue ArgumentError, TypeError
        nil
      end

      # Parses boolean value
      # @param value [String]
      # @return [Boolean, nil]
      def parse_boolean(value)
        return true if %w[true 1 yes oui].include?(value.to_s.downcase)
        return false if %w[false 0 no non].include?(value.to_s.downcase)

        nil
      end

      # Returns the ActiveRecord column definition for a given attribute.
      # Ensures we only build filters on real columns, protecting against SQL injection.
      # @param attribute [String, Symbol]
      # @return [ActiveRecord::ConnectionAdapters::Column, nil]
      def column_for(attribute)
        model_class.columns_hash[attribute.to_s]
      end
    end
  end
end
