# frozen_string_literal: true

module SuperAdmin
  module FormFields
    class TextAreaField < BaseField
      def render
        form.text_area(attribute_name, options)
      end

      def type
        :text_area
      end

      def options
        base_options.merge(rows: 4)
      end
    end
  end
end
