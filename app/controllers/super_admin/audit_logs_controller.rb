# frozen_string_literal: true

module SuperAdmin
  # Read-only view over audit events recorded within SuperAdmin.
  class AuditLogsController < SuperAdmin::BaseController
    before_action :ensure_audit_log_table!

    def index
      scope = SuperAdmin::AuditLog.recent
      scope = scope.where(action: params[:action_type]) if params[:action_type].present?
      scope = scope.where(resource_type: params[:resource_type]) if params[:resource_type].present?
      scope = apply_query(scope)

      @pagy, @audit_logs = pagy(scope, limit: 25)
    end

    private

    def apply_query(scope)
      return scope unless params[:query].present?

      term = "%#{params[:query].to_s.strip.downcase}%"
      scope.where(
        "LOWER(user_email) LIKE :term OR LOWER(resource_type) LIKE :term OR LOWER(action) LIKE :term",
        term: term
      )
    end

    def ensure_audit_log_table!
      return if SuperAdmin::AuditLog.table_exists?

      flash[:alert] = t("super_admin.audit_logs.missing_table")
      redirect_to super_admin_root_path
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
      flash[:alert] = t("super_admin.audit_logs.missing_table")
      redirect_to super_admin_root_path
    end
  end
end
