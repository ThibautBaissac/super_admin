module SuperAdmin
  module ApplicationHelper
    include SuperAdmin::Engine.routes.url_helpers

    def super_admin_root_path
      SuperAdmin::Engine.routes.url_helpers.root_path
    end

    def super_admin_exports_path
      SuperAdmin::Engine.routes.url_helpers.exports_path
    end

    def super_admin_audit_logs_path
      SuperAdmin::Engine.routes.url_helpers.audit_logs_path
    end

    def pagy_nav(pagy)
      return "" unless pagy

      base_params = request.query_parameters.symbolize_keys.except(:page)
      prev_link   = pagy_page_link("Previous", pagy.page - 1, base_params) if pagy.page > 1
      next_link   = pagy_page_link("Next", pagy.page + 1, base_params) if pagy.page < pagy.pages

      content_tag(:nav, class: "pagy-simple-nav", aria: { label: "Pagination" }) do
        safe_join([
          prev_link || pagy_disabled_page_link("Previous"),
          content_tag(:span, "Page #{pagy.page} of #{pagy.pages}", class: "pagy-simple-nav__info"),
          next_link || pagy_disabled_page_link("Next")
        ], "\n".html_safe)
      end
    end

    def audit_action_options
      return [] unless audit_log_ready?

      SuperAdmin::AuditLog.distinct.pluck(:action).compact.sort.map do |action|
        [ action.humanize, action ]
      end
    end

    def audit_resource_options
      return [] unless audit_log_ready?

      SuperAdmin::AuditLog.distinct.pluck(:resource_type).compact.sort.map do |type|
        [ type, type ]
      end
    end

    def action_badge_class(action)
      case action.to_s
      when "create"
        "bg-green-100 text-green-800"
      when "update"
        "bg-blue-100 text-blue-800"
      when "destroy", "bulk_destroy"
        "bg-red-100 text-red-800"
      else
        "bg-gray-100 text-gray-800"
      end
    end

    private

    def pagy_page_link(label, page, params)
      link_to label, pagy_page_url(page, params), class: "pagy-simple-nav__link"
    end

    def pagy_disabled_page_link(label)
      content_tag(:span, label, class: "pagy-simple-nav__link pagy-simple-nav__link--disabled", aria: { disabled: true })
    end

    def pagy_page_url(page, params)
      query = params.merge(page: page).compact_blank
      query_string = query.to_query
      query_string.present? ? "#{request.path}?#{query_string}" : request.path
    end

    def audit_log_ready?
      SuperAdmin::AuditLog.table_exists?
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
      false
    end
  end
end
