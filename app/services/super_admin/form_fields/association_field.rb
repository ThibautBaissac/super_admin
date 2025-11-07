# frozen_string_literal: true

module SuperAdmin
  module FormFields
    class AssociationField < BaseField
      def render
        return safe_text_field(attribute_name) unless association

        total_count = associated_class.count
        records = limited_records

        if total_count > SuperAdmin.association_select_limit
          searchable_select(records, total_count)
        else
          standard_select(records)
        end
      rescue StandardError => e
        Rails.logger.error("SuperAdmin::FormBuilder - Association field error: #{e.message}")
        form.text_field(attribute_name, base_options)
      end

      def type
        :association
      end

      def options
        base_options.except(:required)
      end

      private

      def association
        @association ||= model_class.reflect_on_association(association_name)
      end

      def association_name
        attribute_name.to_s.delete_suffix("_id").to_sym
      end

      def associated_class
        association.klass
      end

      def limited_records
        fetch_records
      end

      def fetch_records
        limit = SuperAdmin.association_select_limit

        if associated_class.column_names.include?("name")
          associated_class.order(:name).limit(limit)
        elsif associated_class.column_names.include?("title")
          associated_class.order(:title).limit(limit)
        elsif associated_class.column_names.include?("created_at")
          associated_class.order(created_at: :desc).limit(limit)
        else
          associated_class.limit(limit)
        end
      end

      def standard_select(records)
        render_select(records, options)
      end

      def searchable_select(records, total_count)
        limited_count = records.size
        selected_record = selected_record_for(records)

        records_for_select = records.to_a
        records_for_select.unshift(selected_record) if selected_record && !records_for_select.include?(selected_record)

        select = render_select(
          records_for_select,
          options.merge(
            class: "#{options[:class]} pr-10",
            data: {
              controller: "super-admin--association-select",
              super_admin__association_select_target: "select",
              association: association_name,
              searchable: "true",
              total_count: total_count
            }
          )
        )

        hint = view_context.content_tag(
          :p,
          view_context.t("super_admin.resources.form.association_limited", count: limited_count, total: total_count),
          class: "mt-1 text-xs text-gray-500"
        )

        view_context.safe_join([ select, hint ])
      end

      def skip_required?
        true
      end

      def safe_text_field(attr)
        if form.object && form.object.respond_to?(attr)
          form.text_field(attr, base_options)
        else
          view_context.text_field_tag(attr, nil, base_options)
        end
      end

      def render_select(records, html_options)
        include_blank = column&.null
        selected_value = current_attribute_value

        if form.object && form.object.respond_to?(attribute_name)
          form.collection_select(
            attribute_name,
            records,
            :id,
            :to_s,
            { include_blank: include_blank, selected: selected_value },
            html_options
          )
        else
          option_tags = view_context.options_from_collection_for_select(records, :id, :to_s, selected_value)
          option_tags = view_context.tag.option("", value: "") + option_tags if include_blank
          view_context.select_tag(attribute_name, option_tags, html_options)
        end
      end

      def current_attribute_value
        if form.object && form.object.respond_to?(attribute_name)
          form.object.public_send(attribute_name)
        end
      end

      def selected_record_for(records)
        value = current_attribute_value
        return unless value

        if records.respond_to?(:find) && records.respond_to?(:detect)
          records.detect { |record| record.id == value } || associated_class.find_by(id: value)
        else
          associated_class.find_by(id: value)
        end
      end
    end
  end
end
