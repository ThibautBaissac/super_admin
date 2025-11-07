# frozen_string_literal: true

module SuperAdmin
  module FormFields
    class NestedField < BaseField
      MAX_DEPTH_SAFETY = 10

      def render
        return missing_association_warning unless reflection
        return max_depth_message if max_depth_exceeded?

        prepare_nested_records

        view_context.render(
          partial: "super_admin/shared/nested_fields",
          locals: {
            form: form,
            parent_model_class: model_class,
            association: reflection,
            nested_model_class: reflection.klass,
            nested_attributes: nested_editable_attributes,
            nested_options: nested_options,
            label: label,
            current_depth: current_depth
          }
        )
      end

      def type
        :nested
      end

      def label
        return association_name.to_s.humanize unless reflection

        count = reflection.collection? ? 2 : 1
        reflection.klass.model_name.human(count: count)
      end

      def options
        {}
      end

      private

      def association_name
        attribute_name.to_s.delete_suffix("_attributes")
      end

      def reflection
        @reflection ||= model_class.reflect_on_association(association_name.to_sym)
      end

      def nested_options
        return {} unless model_class.respond_to?(:nested_attributes_options)

        model_class.nested_attributes_options[association_name.to_sym]
      end

      def nested_editable_attributes
        attributes = SuperAdmin::DashboardResolver.form_attributes_for(reflection.klass)
        attributes = SuperAdmin::ResourceConfiguration.editable_attributes(reflection.klass) if attributes.blank?

        attributes = attributes.reject { |attr| attr.to_s.end_with?("_attributes") }
        attributes = attributes.map { |attr| attr.to_sym }
        attributes -= [ reflection.foreign_key.to_sym ] if reflection.respond_to?(:foreign_key)
        attributes
      end

      def prepare_nested_records
        parent = form.object
        return unless parent
        return if reflection.through_reflection

        if parent.respond_to?(:association)
          association_proxy = parent.association(reflection.name)
          association_proxy.load_target if association_proxy.respond_to?(:load_target)
        else
          parent.public_send(reflection.name)
        end
      end

      def current_depth
        depth = 0
        current_form = form

        while current_form.respond_to?(:object) && current_form.respond_to?(:object_name) && current_form.object_name.to_s.include?("[")
          depth += 1
          parent = current_form.instance_variable_get(:@parent_builder)
          break unless parent

          current_form = parent
          break if depth >= MAX_DEPTH_SAFETY
        end

        depth
      end

      def max_depth_exceeded?
        current_depth >= SuperAdmin.max_nested_depth
      end

      def max_depth_message
        view_context.content_tag(
          :div,
          view_context.content_tag(:p, view_context.t("super_admin.resources.nested.max_depth_exceeded", max: SuperAdmin.max_nested_depth), class: "text-sm text-amber-600"),
          class: "mb-4 bg-amber-50 border border-amber-200 rounded-md p-3"
        )
      end

      def missing_association_warning
        view_context.content_tag(
          :p,
          view_context.t("super_admin.resources.nested.missing_association", name: association_name.humanize),
          class: "text-sm text-red-600"
        )
      end
    end
  end
end
