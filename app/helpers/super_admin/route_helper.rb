module SuperAdmin
  module RouteHelper
    def super_admin_engine
      SuperAdmin::Engine.routes.url_helpers
    end
  end
end
