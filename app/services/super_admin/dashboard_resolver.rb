# frozen_string_literal: true

module SuperAdmin
  # Provides accessors and fallbacks for dashboard-driven configuration.
  class DashboardResolver
    VIEWS = {
      index: :collection,
      collection: :collection,
      list: :collection,
      show: :show,
      detail: :show,
      form: :form,
      new: :form,
      edit: :form
    }.freeze

    class << self
      def dashboard_for(model_class)
        DashboardRegistry.instance.dashboard_for(model_class)
      end

      def collection_attributes_for(model_class)
        attributes_for(model_class, :collection)
      end

      def show_attributes_for(model_class)
        attributes_for(model_class, :show)
      end

      def form_attributes_for(model_class)
        attributes_for(model_class, :form)
      end

      def collection_includes_for(model_class)
        includes_for(model_class, :collection)
      end

      def show_includes_for(model_class)
        includes_for(model_class, :show)
      end

      def includes_for(model_class, view)
        dashboard = dashboard_for(model_class)
        return [] unless dashboard

        case view
        when :collection, :index, :list
          Array.wrap(dashboard.collection_includes_list)
        when :show, :detail
          Array.wrap(dashboard.show_includes_list)
        else
          []
        end
      end

      def attributes_for(model_class, view)
        normalized_view = VIEWS.fetch(view.to_sym, view.to_sym)
        dashboard = dashboard_for(model_class)

        if dashboard
          Array.wrap(dashboard.attributes_for(normalized_view)).map { |attr| normalize_attribute(attr) }
        else
          fallback_attributes(model_class, normalized_view)
        end
      end

      private

      def normalize_attribute(attribute)
        case attribute
        when Hash
          attribute.each_with_object({}) do |(key, value), hash|
            hash[key.to_sym] = Array(value).map { |entry| normalize_attribute(entry) }
          end
        else
          attribute.to_sym
        end
      end

      def fallback_attributes(model_class, view)
        case view
        when :collection
          SuperAdmin::ResourceConfiguration
            .displayable_attributes(model_class)
            .map { |attr| attr.to_sym }
        when :show
          SuperAdmin::ResourceConfiguration
            .displayable_attributes(model_class)
            .map { |attr| attr.to_sym }
        when :form
          SuperAdmin::ResourceConfiguration
            .editable_attributes(model_class)
            .map { |attr| attr.is_a?(String) ? attr.to_sym : attr }
        else
          []
        end
      end
    end
  end
end
