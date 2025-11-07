# frozen_string_literal: true

require "ostruct"

module SuperAdmin
  # Base controller for all SuperAdmin controllers.
  # Handles authentication, authorization, and custom layout.
  class BaseController < SuperAdmin::ApplicationController
    before_action :authorize_super_admin!

    private

    # Pagy helper method for pagination
    # Returns a simple pagination object and the paginated collection
    def pagy(collection, **vars)
      # Set default items per page
      items_per_page = vars.delete(:limit) || 25

      # Get current page from params
      page = (params[:page] || 1).to_i
      page = 1 if page < 1

      # Calculate total count
      count = collection.count

      # Calculate pagination values
      pages = (count.to_f / items_per_page).ceil
      pages = 1 if pages < 1
      page = pages if page > pages

      offset = (page - 1) * items_per_page

      # Create a simple pagination object
      pagy_obj = OpenStruct.new(
        count: count,
        page: page,
        items: items_per_page,
        pages: pages,
        offset: offset,
        limit: items_per_page,
        next: (page < pages ? page + 1 : nil),
        prev: (page > 1 ? page - 1 : nil),
        in: [ [ (offset + 1), count ].min, [ offset + items_per_page, count ].min ]
      )

      # Return paginated collection
      [ pagy_obj, collection.offset(offset).limit(items_per_page) ]
    end

    def authorize_super_admin!
      return if SuperAdmin::Authorization.call(self)

      # Si call retourne false, l'adapter a déjà géré la réponse (redirect/render).
      # On stoppe la suite du traitement via la primitive Rack disponible.
      if request.respond_to?(:halt)
        request.halt
      end

      false
    end

    def available_models
      @available_models ||= SuperAdmin::ModelInspector.all_models
    end
    helper_method :available_models

    def model_display_name(model_class)
      model_class.model_name.human(count: 2)
    end
    helper_method :model_display_name

    def model_path(model_class)
      SuperAdmin::Engine.routes.url_helpers.resources_path(resource: model_class.name.underscore.pluralize)
    end
    helper_method :model_path

    # Helper methods for routes that work in both standalone and mounted engine contexts
    def super_admin_root_path
      SuperAdmin::Engine.routes.url_helpers.root_path
    end
    helper_method :super_admin_root_path

    def super_admin_exports_path
      SuperAdmin::Engine.routes.url_helpers.exports_path
    end
    helper_method :super_admin_exports_path

    def super_admin_audit_logs_path
      SuperAdmin::Engine.routes.url_helpers.audit_logs_path
    end
    helper_method :super_admin_audit_logs_path

    def super_admin_export_path(token)
      SuperAdmin::Engine.routes.url_helpers.export_path(token)
    end
    helper_method :super_admin_export_path

    def download_super_admin_export_path(token)
      SuperAdmin::Engine.routes.url_helpers.download_export_path(token)
    end
    helper_method :download_super_admin_export_path

    def super_admin_resources_path(options = {})
      SuperAdmin::Engine.routes.url_helpers.resources_path(options)
    end
    helper_method :super_admin_resources_path

    def super_admin_resource_path(options = {})
      SuperAdmin::Engine.routes.url_helpers.resource_path(options)
    end
    helper_method :super_admin_resource_path

    def super_admin_new_resource_path(options = {})
      SuperAdmin::Engine.routes.url_helpers.new_resource_path(options)
    end
    helper_method :super_admin_new_resource_path

    def super_admin_edit_resource_path(options = {})
      SuperAdmin::Engine.routes.url_helpers.edit_resource_path(options)
    end
    helper_method :super_admin_edit_resource_path

    def super_admin_bulk_action_path(options = {})
      SuperAdmin::Engine.routes.url_helpers.bulk_action_path(options)
    end
    helper_method :super_admin_bulk_action_path

    def super_admin_association_search_path(options = {})
      SuperAdmin::Engine.routes.url_helpers.association_search_path(options)
    end
    helper_method :super_admin_association_search_path
  end
end
