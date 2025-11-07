# frozen_string_literal: true

require "singleton"

module SuperAdmin
  # Discovers and caches dashboard classes for SuperAdmin resources.
  class DashboardRegistry
    include Singleton

    def initialize
      @dashboards = {}
      @resource_classes = {}
      @loaded = false
      setup_reloader
    end

    # Returns the dashboard class for a given model or resource name.
    # @param model [Class, String, Symbol]
    # @return [Class, nil]
    def dashboard_for(model)
      load_dashboards unless @loaded

      @dashboards[normalize_model_name(model)]
    end

    # Returns the list of resource classes that have an associated dashboard.
    # @return [Array<Class>]
    def resource_classes
      load_dashboards unless @loaded

      @resource_classes.values.sort_by(&:name)
    end

    # Reloads dashboard definitions (used in development).
    def reload!
      @dashboards.clear
      @resource_classes.clear
      @loaded = false
      load_dashboards
    end

    private

    def setup_reloader
      return unless defined?(ActiveSupport::Reloader)

      ActiveSupport::Reloader.to_prepare do
        @dashboards ||= {}
        @dashboards.clear
        @resource_classes ||= {}
        @resource_classes.clear
        @loaded = false
      end
    end

    def load_dashboards
      eager_load_dashboard_files
      register_dashboard_classes
      @loaded = true
    end

    def eager_load_dashboard_files
      pattern = Rails.root.join("app/dashboards/**/*_dashboard.rb")
      Dir[pattern].each { |file| require_dependency(file) }
    end

    def register_dashboard_classes
      ObjectSpace.each_object(Class) do |klass|
        next unless klass < SuperAdmin::BaseDashboard

        resource_class = klass.resource_class
        next unless resource_class

        @dashboards[resource_class.name] = klass
        @resource_classes[resource_class.name] = resource_class
      end
    end

    def normalize_model_name(model)
      case model
      when Class
        model.name
      when String, Symbol
        model.to_s.underscore.singularize.camelize
      else
        model.class.name
      end
    end
  end
end
