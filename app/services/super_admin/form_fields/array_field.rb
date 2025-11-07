# frozen_string_literal: true

module SuperAdmin
  module FormFields
    # Renders a textarea optimized for array-backed attributes.
    class ArrayField < TextAreaField
      def render
        form.text_area(attribute_name, options.merge(value: formatted_value))
      end

      def type
        :array
      end

      private

      def formatted_value
        value = form.object.public_send(attribute_name)
        return "" if value.blank?

        Array(value).map(&:to_s).join("\n")
      rescue NoMethodError
        ""
      end

      def options
        base_options.merge(rows: 4, placeholder: placeholder_text)
      end

      def placeholder_text
        I18n.t("super_admin.resources.form.array_placeholder", default: "Enter one value per line or separate with commas")
      end
    end
  end
end
