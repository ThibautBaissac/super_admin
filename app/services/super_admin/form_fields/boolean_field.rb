# frozen_string_literal: true

module SuperAdmin
  module FormFields
    class BooleanField < BaseField
      def render
        form.check_box(attribute_name, class: input_css_class)
      end

      def type
        :boolean
      end

      def options
        { class: input_css_class }
      end

      private

      def input_css_class
        "h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
      end

      def skip_required?
        true
      end
    end
  end
end
