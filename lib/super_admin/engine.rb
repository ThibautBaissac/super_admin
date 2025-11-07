module SuperAdmin
  # :nocov:
  class Engine < ::Rails::Engine
    isolate_namespace SuperAdmin

    initializer "super_admin.assets" do |app|
      # Add engine's JavaScript to asset paths so they can be served
      app.config.assets.paths << root.join("app/javascript") if app.config.respond_to?(:assets)
      # Add engine's stylesheets to asset paths for propshaft/sprockets
      app.config.assets.paths << root.join("app/assets/stylesheets") if app.config.respond_to?(:assets)
    end

    initializer "super_admin.importmap", before: "importmap" do |app|
      # Register SuperAdmin importmap if importmap-rails is available
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/javascript")
      end
    end

    initializer "super_admin.route_helpers" do
      require_relative "../../app/helpers/super_admin/route_helper"

      ActiveSupport.on_load(:action_view) do
        include ::SuperAdmin::RouteHelper
      end

      ActiveSupport.on_load(:action_controller) do
        helper ::SuperAdmin::RouteHelper
      end

      config.to_prepare do
        if defined?(ViewComponent::Base) && !ViewComponent::Base.included_modules.include?(::SuperAdmin::RouteHelper)
          ViewComponent::Base.include(::SuperAdmin::RouteHelper)
        end

        if defined?(ActionView::Component::Base) && !ActionView::Component::Base.included_modules.include?(::SuperAdmin::RouteHelper)
          ActionView::Component::Base.include(::SuperAdmin::RouteHelper)
        end
      end
    end

    initializer "super_admin.rack_attack", after: :load_config_initializers do
      # Load Rack::Attack configuration for SuperAdmin endpoints
      if defined?(Rack::Attack)
        require "rack-attack"
        config_file = root.join("config/initializers/rack_attack.rb")
        load(config_file) if config_file.exist?
      end
    end
  end
  # :nocov:
end
