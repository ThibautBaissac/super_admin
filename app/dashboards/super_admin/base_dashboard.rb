# frozen_string_literal: true

module SuperAdmin
  # Base DSL to configure how resources are displayed inside SuperAdmin.
  # Inspired by Administrate dashboards but focused on selecting visible attributes.
  class BaseDashboard
    class_attribute :_resource_class, instance_writer: false
    class_attribute :_collection_attributes, default: nil, instance_writer: false
    class_attribute :_show_attributes, default: nil, instance_writer: false
    class_attribute :_form_attributes, default: nil, instance_writer: false
    class_attribute :_collection_includes, default: nil, instance_writer: false
    class_attribute :_show_includes, default: nil, instance_writer: false

    class << self
      # Explicitly sets the resource class managed by this dashboard.
      # When omitted, the class is inferred from the dashboard name (e.g. UserDashboard => User).
      def resource(model_class)
        self._resource_class = model_class
      end

      # Defines attributes shown on the collection (index) page.
      # Usage: collection_attributes :id, :name, :status
      def collection_attributes(*attrs)
        self._collection_attributes = normalize_flat_attribute_list(attrs)
      end

      # Defines attributes shown on the resource detail (show) page.
      def show_attributes(*attrs)
        self._show_attributes = normalize_flat_attribute_list(attrs)
      end

      # Defines attributes shown in resource forms (new/edit).
      def form_attributes(*attrs)
        self._form_attributes = normalize_flat_attribute_list(attrs)
      end

      # Defines associations to preload for the collection (index) page to avoid N+1 queries.
      # Usage: collection_includes :author, :tags, comments: :user
      def collection_includes(*associations)
        self._collection_includes = associations.freeze
      end

      # Defines associations to preload for the show page to avoid N+1 queries.
      # Usage: show_includes :author, :tags, comments: :user
      def show_includes(*associations)
        self._show_includes = associations.freeze
      end

      # Returns the ActiveRecord class associated with the dashboard.
      def resource_class
        resolved_resource_class || infer_resource_class
      end

      # Returns attributes configured for a given view.
      def attributes_for(view)
        case view.to_sym
        when :index, :collection, :list
          collection_attributes_list
        when :show, :detail
          show_attributes_list
        when :form, :new, :edit
          form_attributes_list
        else
          []
        end
      end

      # Returns configured collection attributes or sensible defaults.
      def collection_attributes_list
        _collection_attributes || default_collection_attributes
      end

      # Returns configured show attributes or sensible defaults.
      def show_attributes_list
        _show_attributes || default_show_attributes
      end

      # Returns configured form attributes or sensible defaults.
      def form_attributes_list
        _form_attributes || default_form_attributes
      end

      # Returns associations to preload for collection view
      def collection_includes_list
        _collection_includes || default_collection_includes
      end

      # Returns associations to preload for show view
      def show_includes_list
        _show_includes || default_show_includes
      end

      private

      def resolved_resource_class
        case _resource_class
        when Class
          _resource_class
        when String, Symbol
          _resource_class.to_s.constantize
        else
          nil
        end
      rescue NameError
        nil
      end

      def normalize_attribute_list(attrs)
        Array(attrs).flatten.compact.map do |attribute|
          normalize_attribute_entry(attribute)
        end.freeze
      end

      def normalize_flat_attribute_list(attrs)
        normalize_attribute_list(attrs).flat_map do |entry|
          entry.is_a?(Hash) ? entry.keys.map(&:to_sym) : entry
        end.map(&:to_sym).freeze
      end

      def normalize_attribute_entry(attribute)
        case attribute
        when Hash
          attribute.each_with_object({}) do |(key, value), hash|
            hash[key.to_sym] = Array(value).flatten.compact.map { |entry| normalize_attribute_entry(entry) }
          end
        else
          attribute.to_sym
        end
      end

      def infer_resource_class
        name.delete_suffix("Dashboard").constantize
      rescue NameError
        nil
      end

      def default_collection_attributes
        default_displayable_attributes
      end

      def default_show_attributes
        default_displayable_attributes
      end

      def default_form_attributes
        resource = resource_class
        return [] unless resource

        editable = SuperAdmin::ResourceConfiguration.editable_attributes(resource)
        editable.map { |attr| attr.to_sym }
      end

      def default_displayable_attributes
        resource = resource_class
        return [] unless resource

        attrs = SuperAdmin::ResourceConfiguration.displayable_attributes(resource)
        attrs.map { |attr| attr.to_sym }
      end

      def default_collection_includes
        resource = resource_class
        return [] unless resource

        # Auto-detect preloadable associations explicitly listed in the collection attributes
        associations_from_attributes(collection_attributes_list, resource)
      end

      def default_show_includes
        resource = resource_class
        return [] unless resource

        # Auto-detect belongs_to and has_one associations which benefit from eager loading
        preloadable_association_names(resource)
      rescue StandardError
        []
      end

      def associations_from_attributes(attributes, resource)
        return [] unless resource.respond_to?(:reflect_on_all_associations)

        preloadable_associations = preloadable_association_names(resource)

        # Only preload associations explicitly referenced in the attribute list.
        attributes.select do |attr|
          preloadable_associations.include?(attr)
        end.uniq
      rescue StandardError
        []
      end

      def preloadable_association_names(resource)
        resource.reflect_on_all_associations
          .select { |reflection| %i[belongs_to has_one].include?(reflection.macro) }
          .reject(&:polymorphic?)
          .map(&:name)
      end
    end
  end
end
