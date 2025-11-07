# frozen_string_literal: true

module SuperAdmin
  module FormFields
    class NumberField < BaseField
      def render
        form.number_field(attribute_name, options)
      end

      def type
        :number
      end

      def options
        base_options.merge(step: step_value)
      end

      private

      def step_value
        column = builder.column
        return "0.01" if column&.type == :decimal && column.scale && column.scale.positive?
        return "0.01" if column&.type == :float

        "1"
      end
    end
  end
end
