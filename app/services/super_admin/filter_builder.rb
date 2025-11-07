# frozen_string_literal: true

require "bigdecimal"
require "digest"

module SuperAdmin
  # Dynamically builds available filters for a SuperAdmin resource
  # and applies associated conditions on an ActiveRecord relation.
  class FilterBuilder
    FilterDefinition = Struct.new(:attribute, :type, :param_keys, :label, :options, keyword_init: true)

    CACHE_NAMESPACE = "super_admin/filter_definitions".freeze
    CACHE_EXPIRATION = 1.hour

    STRING_TYPES = %i[string text].freeze
    NUMERIC_TYPES = %i[integer float decimal].freeze
    DATE_TYPES = %i[date datetime].freeze
    BOOLEAN_TYPES = %i[boolean].freeze

    class << self
      # Returns filter definitions for a given model class.
      # @param model_class [Class]
      # @return [Array<FilterDefinition>]
      def definitions_for(model_class)
        Rails.cache.fetch(cache_key_for(model_class), expires_in: CACHE_EXPIRATION) do
          new(model_class).definitions
        end
      end

      # Returns list of permitted parameter keys for filters.
      # @param model_class [Class]
      # @return [Array<Symbol>]
      def permitted_param_keys(model_class)
        definitions_for(model_class).flat_map(&:param_keys).uniq
      end

      # Applies filters on an ActiveRecord relation.
      # @param scope [ActiveRecord::Relation]
      # @param model_class [Class]
      # @param params [Hash]
      # @return [ActiveRecord::Relation]
      def apply(scope, model_class, params)
        return scope if params.blank?

        SuperAdmin::Queries::FilterQuery.new(
          scope,
          model_class,
          filters: params,
          filter_definitions: definitions_for(model_class)
        ).call
      end

      private

      def cache_key_for(model_class)
        columns_signature = model_class.columns_hash.values.map do |column|
          [ column.name, column.sql_type, column.default, column.null ]
        end
        enums_signature = model_class.respond_to?(:defined_enums) ? model_class.defined_enums : {}
        digest_source = [ model_class.name, columns_signature, enums_signature ].to_s
        digest = Digest::SHA256.hexdigest(digest_source)
        "#{CACHE_NAMESPACE}/#{model_class.name}/#{digest}"
      end

      # DEPRECATED: These methods are kept for compatibility but no longer used.
      # Logic has been moved to SuperAdmin::Queries::FilterQuery

      def apply_string_filter(scope, arel_table, attribute, value)
        SuperAdmin::Queries::FilterQuery.new(scope, scope.model, filters: { "#{attribute}_contains" => value }).call
      end

      def apply_numeric_filter(scope, arel_table, attribute, type, params)
        SuperAdmin::Queries::FilterQuery.new(scope, scope.model, filters: params).call
      end

      def apply_date_filter(scope, arel_table, attribute, type, params)
        SuperAdmin::Queries::FilterQuery.new(scope, scope.model, filters: params).call
      end

      def apply_boolean_filter(scope, attribute, value)
        SuperAdmin::Queries::FilterQuery.new(scope, scope.model, filters: { "#{attribute}_equals" => value }).call
      end

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

      def parse_boolean(value)
        return true if %w[true 1 yes oui].include?(value.to_s.downcase)
        return false if %w[false 0 no non].include?(value.to_s.downcase)

        nil
      end
    end

    attr_reader :model_class

    def initialize(model_class)
      @model_class = model_class
    end

    # Returns computed definitions (memoized)
    # @return [Array<FilterDefinition>]
    def definitions
      @definitions ||= build_definitions
    end

    private

    def build_definitions
      enums = enum_attributes

      model_class.columns.filter_map do |column|
        next if %w[id created_at updated_at].include?(column.name)

        attribute = column.name
        label = model_class.human_attribute_name(attribute)

        if enums.key?(attribute)
          FilterDefinition.new(
            attribute: attribute,
            type: :enum,
            param_keys: [ "#{attribute}_equals".to_sym ],
            label: label,
            options: enums[attribute].keys
          )
        elsif STRING_TYPES.include?(column.type)
          FilterDefinition.new(
            attribute: attribute,
            type: column.type,
            param_keys: [ "#{attribute}_contains".to_sym ],
            label: label
          )
        elsif NUMERIC_TYPES.include?(column.type)
          FilterDefinition.new(
            attribute: attribute,
            type: column.type,
            param_keys: [ "#{attribute}_min".to_sym, "#{attribute}_max".to_sym ],
            label: label
          )
        elsif DATE_TYPES.include?(column.type)
          FilterDefinition.new(
            attribute: attribute,
            type: column.type,
            param_keys: [ "#{attribute}_from".to_sym, "#{attribute}_to".to_sym ],
            label: label
          )
        elsif BOOLEAN_TYPES.include?(column.type)
          FilterDefinition.new(
            attribute: attribute,
            type: :boolean,
            param_keys: [ "#{attribute}_equals".to_sym ],
            label: label
          )
        end
      end
    end

    def enum_attributes
      return {} unless model_class.respond_to?(:defined_enums)

      model_class.defined_enums
    end
  end
end
