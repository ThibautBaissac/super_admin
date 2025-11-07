# frozen_string_literal: true

module SuperAdmin
  module Resources
    # Wraps information about the requested resource to avoid leaking controller logic.
    class Context
      attr_reader :resource_param

      def initialize(resource_param)
        @resource_param = resource_param.to_s
      end

      def valid?
        SuperAdmin::ModelInspector.find_model(resource_param).present?
      end

      def resource_name
        resource_param
      end

      def singular_name
        resource_name.singularize
      end

      def plural_name
        resource_name.pluralize
      end

      def model_class
        @model_class ||= begin
          klass = SuperAdmin::ModelInspector.find_model(resource_param)
          raise NameError, "Unrecognized resource '#{resource_param}'" unless klass

          klass
        end
      end

      def dashboard
        SuperAdmin::DashboardResolver.dashboard_for(model_class)
      end

      def displayable_attributes
        SuperAdmin::DashboardResolver.collection_attributes_for(model_class)
      end

      def show_attributes
        SuperAdmin::DashboardResolver.show_attributes_for(model_class)
      end

      def editable_attributes
        SuperAdmin::DashboardResolver.form_attributes_for(model_class)
      end

      def human_model_name(count: 1)
        model_class.model_name.human(count: count)
      end

      def param_key
        model_class.model_name.param_key
      end
    end
  end
end
