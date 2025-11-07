# frozen_string_literal: true

module SuperAdmin
  # Helper for SuperAdmin views
  module ResourcesHelper
    # Formats attribute value for display
    # @param resource [ActiveRecord::Base] The record
    # @param attribute [String, Symbol] The attribute name
    # @return [String] Formatted value
    def format_attribute_value(resource, attribute)
      value = resource.send(attribute)

      case value
      when nil
        content_tag(:span, "—", class: "text-gray-400 italic")
      when true
        content_tag(:span, "✓", class: "text-green-600 font-bold")
      when false
        content_tag(:span, "✗", class: "text-red-600 font-bold")
      when Date
        l(value, format: :long)
      when Time, DateTime, ActiveSupport::TimeWithZone
        l(value, format: :long)
      when Integer
        number_with_delimiter(value)
      when Float, BigDecimal
        number_with_precision(value, precision: 2, delimiter: " ")
      when String
        value.present? ? value : content_tag(:span, t("super_admin.helpers.resources.empty_string"), class: "text-gray-400 italic")
      else
        value.to_s
      end
    end

    # Displays the attribute value in a basic textual form used by tests and plain lists.
    def display_attribute(resource, attribute)
      value = resource.public_send(attribute)

      return "" if value.nil?

      # Handle ActiveRecord associations gracefully
      if (reflection = resource.class.reflect_on_association(attribute))
        return display_association_value(value, reflection)
      end

      # Enum attributes should be humanized
      if resource.class.respond_to?(:defined_enums) && resource.class.defined_enums.key?(attribute.to_s)
        return humanize_enum_value(resource, attribute, value)
      end

      case value
      when TrueClass, FalseClass
        value ? "Yes" : "No"
      when Time, Date, DateTime, ActiveSupport::TimeWithZone
        I18n.l(value)
      else
        value.to_s
      end
    end

    # Humanizes a raw attribute name for display purposes.
    def humanize_attribute(attribute)
      attribute.to_s.tr("_", " ").capitalize
    end

    private

    def display_association_value(value, reflection)
      if reflection.collection?
        value.map { |record| association_display_name(record) }.reject(&:blank?).join(", ")
      else
        association_display_name(value)
      end
    end

    def association_display_name(record)
      %i[name title email to_s].each do |method|
        next unless record.respond_to?(method)

        result = record.public_send(method)
        return result.to_s if result.present?
      end

      ""
    end

    def humanize_enum_value(resource, attribute, value)
      return "" if value.blank?

      i18n_key = "#{attribute}.#{value}"
      translation = resource.class.human_attribute_name(i18n_key, default: "")
      return translation if translation.present?

      value.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
    end

    # Returns CSS class for status badge
    # @param value [Object] The value to badge
    # @return [String] CSS classes
    def badge_class_for(value)
      case value
      when true
        "bg-green-100 text-green-800"
      when false
        "bg-red-100 text-red-800"
      when nil
        "bg-gray-100 text-gray-800"
      else
        "bg-blue-100 text-blue-800"
      end
    end

    # Returns icon for a column type
    # @param column_type [Symbol] The column type
    # @return [String] SVG icon
    def icon_for_column_type(column_type)
      icons = {
        string: "M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129",
        text: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z",
        integer: "M7 20l4-16m2 16l4-16M6 9h14M4 15h14",
        decimal: "M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z",
        boolean: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z",
        date: "M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z",
        datetime: "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
      }

      path = icons[column_type] || icons[:string]

      content_tag(:svg, class: "h-4 w-4", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, "", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: path)
      end
    end

    # Returns humanized label for a model
    # @param model_class [Class] The model class
    # @param count [Integer] Number for pluralization
    # @return [String] Humanized label
    def humanize_model_name(model_class, count: 2)
      model_class.model_name.human(count: count)
    end

    # Generates sort options for a column
    # @param attribute [String] The attribute name
    # @param current_sort [String] Current sort attribute
    # @param current_direction [String] Current sort direction
    # @return [Hash] Parameters for sort link
    def sort_params_for(attribute, current_sort: params[:sort], current_direction: params[:direction])
      if current_sort == attribute
        # Reverse direction if already sorting on this column
        direction = current_direction == "asc" ? "desc" : "asc"
      else
        # Default direction
        direction = "asc"
      end

      { sort: attribute, direction: direction }
    end

    # Returns sort indicator for a column
    # @param attribute [String] The attribute name
    # @param current_sort [String] Current sort attribute
    # @param current_direction [String] Current sort direction
    # @return [String, nil] Sort icon or nil
    def sort_indicator_for(attribute, current_sort: params[:sort], current_direction: params[:direction])
      return unless current_sort == attribute

      if current_direction == "asc"
        "↑"
      else
        "↓"
      end
    end

    # Returns the current filter value to prefill forms
    # @param applied_filters [Hash]
    # @param key [String, Symbol]
    # @return [String]
    def filter_value(applied_filters, key)
      return "" unless applied_filters

      applied_filters[key.to_s] || applied_filters[key.to_sym] || ""
    end

    # Formats datetime value for datetime-local input field
    def filter_datetime_value(applied_filters, key)
      raw_value = filter_value(applied_filters, key)
      return "" if raw_value.blank?

      Time.zone.parse(raw_value.to_s).strftime("%Y-%m-%dT%H:%M")
    rescue ArgumentError
      raw_value
    end

    # Formats date value for date input field
    def filter_date_value(applied_filters, key)
      raw_value = filter_value(applied_filters, key)
      return "" if raw_value.blank?

      Date.parse(raw_value.to_s).strftime("%Y-%m-%d")
    rescue ArgumentError
      raw_value
    end
  end
end
