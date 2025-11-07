# frozen_string_literal: true

module SuperAdmin
  module FormFields
    class DateField < BaseField
      def render
        form.date_field(attribute_name, options)
      end

      def type
        :date
      end
    end
  end
end
