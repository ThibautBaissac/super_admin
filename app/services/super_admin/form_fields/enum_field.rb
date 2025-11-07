# frozen_string_literal: true

module SuperAdmin
  module FormFields
    class EnumField < BaseField
      def render
        form.select(attribute_name, enum_options, { include_blank: include_blank_option }, options.except(:required))
      end

      def type
        :enum
      end

      private

      def enum_options
        SuperAdmin::ModelInspector.enum_values(model_class, attribute_name).keys.map do |key|
          [ key.humanize, key ]
        end
      end

      def include_blank_option
        column&.null ? true : nil
      end
    end
  end
end
