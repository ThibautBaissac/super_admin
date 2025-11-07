# frozen_string_literal: true

module SuperAdmin
  module FormFields
    # Base class for SuperAdmin form fields.
    class BaseField
      attr_reader :builder

      delegate :form, :model_class, :attribute_name, :column, :view_context, to: :builder

      def initialize(builder)
        @builder = builder
      end

      def render
        form.text_field(attribute_name, options)
      end

      def type
        :text
      end

      def options
        base_options
      end

      def label
        model_class.human_attribute_name(attribute_name)
      end

      protected

      def base_options
        @base_options ||= begin
          input_options = { class: input_css_class }
          if column
            input_options[:required] = !column.null unless skip_required?
            input_options[:maxlength] = column.limit if column.limit
          end
          input_options
        end
      end

      def input_css_class
        "block w-full rounded-md border-2 border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2"
      end

      def skip_required?
        %w[created_at updated_at id].include?(attribute_name.to_s)
      end
    end
  end
end
