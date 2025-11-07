# frozen_string_literal: true

require "set"

module SuperAdmin
  module Resources
    # Computes the strong parameters list for a given resource, including nested attributes.
    class PermittedAttributes
      attr_reader :model_class

      def initialize(model_class)
        @model_class = model_class
      end

      # Make the class callable, returning the list of permitted attribute names
      def call
        attribute_names
      end

      def permit(params)
        params.require(param_key).permit(*attribute_names)
      end

      def attribute_names
        @attribute_names ||= begin
          dashboard_form_attrs = SuperAdmin::DashboardResolver.form_attributes_for(model_class)

          direct_attributes = SuperAdmin::ResourceConfiguration
            .editable_attributes(model_class)
            .reject { |attr| attr.to_s.end_with?("_attributes") }
            .map(&:to_sym)

          allowed_direct = if dashboard_form_attrs.present?
            dashboard_form_attrs
              .reject { |attr| attr.to_s.end_with?("_attributes") }
              .map(&:to_sym)
          else
            []
          end

          if allowed_direct.present?
            direct_attributes &= allowed_direct
          end

          # Filter out sensitive attributes for security (defense-in-depth)
          direct_attributes = SuperAdmin::SensitiveAttributes.filter(
            direct_attributes,
            model_class: model_class,
            allowlist: allowed_direct
          )

          direct_attributes + nested_attribute_definitions(dashboard_form_attrs)
        end
      end

      private

      def param_key
        model_class.model_name.param_key
      end

      def nested_attribute_definitions(dashboard_form_attrs)
        allowlist = if dashboard_form_attrs.present?
          dashboard_form_attrs.select { |attr| attr.to_s.end_with?("_attributes") }.map do |attr|
            attr.to_s.delete_suffix("_attributes").to_sym
          end.to_set
        end

        allowlist = nil if allowlist&.empty?

        Array(model_class.nested_attributes_options).filter_map do |association_name, options|
          if allowlist && !allowlist.include?(association_name.to_sym)
            next
          end

          reflection = model_class.reflect_on_association(association_name)
          next unless reflection

          nested_keys = SuperAdmin::ResourceConfiguration
            .editable_attributes(reflection.klass)
            .reject { |attr| attr.to_s.end_with?("_attributes") }
            .map(&:to_sym)

          # Filter out sensitive attributes from nested attributes too
          nested_keys = SuperAdmin::SensitiveAttributes.filter(
            nested_keys,
            model_class: reflection.klass
          )

          nested_keys -= [ reflection.foreign_key.to_sym ] if reflection.respond_to?(:foreign_key)
          nested_keys << :id unless nested_keys.include?(:id)

          # Always permit `_destroy` so nested forms can request deletions, even
          # when the association does not explicitly enable allow_destroy. Rails
          # will ignore the flag if the association disallows it, but permitting
          # the parameter keeps the API consistent across nested resources.
          nested_keys << :_destroy unless nested_keys.include?(:_destroy)

          { "#{association_name}_attributes".to_sym => nested_keys }
        end
      end
    end
  end
end
