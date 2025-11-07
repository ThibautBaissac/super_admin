# frozen_string_literal: true

module SuperAdmin
  module FormFields
    # Responsible for selecting the correct form field class
    # based on the attribute metadata exposed by the FormBuilder.
    class Factory
      ASSOCIATION_SUFFIX = "_id".freeze
      NESTED_SUFFIX = "_attributes".freeze

      class << self
        def build(builder)
          new(builder).build
        end
      end

      def initialize(builder)
        @builder = builder
      end

      def build
        field_klass.new(builder)
      rescue StandardError => e
        Rails.logger.error("SuperAdmin::FormFields::Factory build error: #{e.message}")
        BaseField.new(builder)
      end

      private

      attr_reader :builder

      delegate :model_class, :attribute_name, :column, to: :builder

      def field_klass
  return NestedField if nested_attribute?
  return AssociationField if association_attribute?
  return EnumField if enum_attribute?
  return BooleanField if boolean_attribute?
  return DateTimeField if datetime_attribute?
  return DateField if date_attribute?
  return NumberField if number_attribute?
  return ArrayField if array_attribute?
  return TextAreaField if text_area_attribute?

        BaseField
      end

      def nested_attribute?
        attribute_name.to_s.end_with?(NESTED_SUFFIX)
      end

      def association_attribute?
        association_name && model_class.reflect_on_association(association_name)
      end

      def association_name
        return @association_name if defined?(@association_name)

        name = attribute_name.to_s
        @association_name = name.end_with?(ASSOCIATION_SUFFIX) ? name.delete_suffix(ASSOCIATION_SUFFIX).to_sym : nil
      end

      def enum_attribute?
        SuperAdmin::ModelInspector.enum_values(model_class, attribute_name).present?
      rescue StandardError
        false
      end

      def boolean_attribute?
        column_type?(:boolean)
      end

      def datetime_attribute?
        column_type?(:datetime, :timestamp)
      end

      def date_attribute?
        column_type?(:date)
      end

      def number_attribute?
        column_type?(:integer, :float, :decimal, :bigint)
      end

      def text_area_attribute?
        column_type?(:text)
      end

      def column_type?(*types)
        return false unless column

        types.include?(column.type)
      end

      def array_attribute?
        return false unless column

        column.respond_to?(:array) && column.array
      end
    end
  end
end
