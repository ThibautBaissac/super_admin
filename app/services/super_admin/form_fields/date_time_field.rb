# frozen_string_literal: true

module SuperAdmin
  module FormFields
    class DateTimeField < BaseField
      def render
        form.datetime_local_field(attribute_name, options)
      end

      def type
        :datetime
      end
    end
  end
end
