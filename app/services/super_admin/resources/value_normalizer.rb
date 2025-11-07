# frozen_string_literal: true

require "bigdecimal"

module SuperAdmin
  module Resources
    # Normalizes permitted attribute values before assignment, applying
    # lightweight casting for data types that HTML forms cannot express directly.
    class ValueNormalizer
      ARRAY_DELIMITER_REGEX = /[,\n]/.freeze

      def initialize(model_class, params)
        @model_class = model_class
        @params = params
      end

      # Returns a normalized copy of the permitted parameters.
      def normalize
        return params unless params.is_a?(ActionController::Parameters) && params.permitted?

        normalize_params_for(model_class, params)
        params
      end

      private

      attr_reader :model_class, :params

      def normalize_params_for(current_model, current_params)
        current_params.keys.each do |key|
          string_key = key.to_s
          value = current_params[key]

          if nested_attribute?(string_key)
            normalize_nested_attribute(current_model, string_key, value)
            next
          end

          column = current_model.columns_hash[string_key]
          next unless column

          if array_column?(column)
            current_params[key] = normalize_array_value(column, value)
          end
        end
      end

      def nested_attribute?(key)
        key.end_with?("_attributes")
      end

      def normalize_nested_attribute(current_model, key, value)
        association_name = key.delete_suffix("_attributes")
        reflection = current_model.reflect_on_association(association_name)
        return unless reflection

        case value
        when ActionController::Parameters
          normalize_params_for(reflection.klass, value)
        when Array
          value.each do |entry|
            next unless entry.is_a?(ActionController::Parameters)

            normalize_params_for(reflection.klass, entry)
          end
        end
      end

      def array_column?(column)
        column.respond_to?(:array) && column.array
      end

      def normalize_array_value(column, value)
        array = case value
        when String
          parse_array_string(value)
        when Array
          value.compact
        else
          Array(value)
        end

        cast_array_elements(array, column)
      end

      def parse_array_string(value)
        value.to_s.split(ARRAY_DELIMITER_REGEX).map(&:strip).reject(&:blank?)
      end

      def cast_array_elements(array, column)
        array.filter_map do |element|
          next if element.blank?

          cast_element(element, column)
        end
      end

      def cast_element(element, column)
        return element unless element.is_a?(String)

        stripped = element.strip
        return nil if stripped.blank?

        case column.type
        when :integer, :bigint
          Integer(stripped, exception: false) || stripped
        when :float
          Float(stripped, exception: false) || stripped
        when :decimal
          BigDecimal(stripped)
        when :boolean
          ActiveModel::Type::Boolean.new.cast(stripped) || stripped
        else
          stripped
        end
      rescue ArgumentError, TypeError
        stripped
      end
    end
  end
end
