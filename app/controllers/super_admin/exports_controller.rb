# frozen_string_literal: true

module SuperAdmin
  # Handles creation and tracking of SuperAdmin CSV exports.
  class ExportsController < SuperAdmin::BaseController
    helper SuperAdmin::ExportsHelper

    before_action :load_model_class, only: :create
    before_action :find_export, only: %i[show download destroy]

    def index
      exports_scope = current_user.csv_exports.recent_first
      exports_scope = exports_scope.includes(:file_attachment) if active_storage_available?
      @pagy, @exports = pagy(exports_scope, limit: 20)
    end

    def show
      nil if performed?
    end

    def create
      return if performed?

      filters = sanitized_filters(@model_class, params[:filters])

      export = SuperAdmin::CsvExportCreator.call(
        user: current_user,
        model_class: @model_class,
        resource: params[:resource],
        search: params[:search],
        sort: params[:sort],
        direction: params[:direction],
        filters: filters,
        attributes: SuperAdmin::DashboardResolver.collection_attributes_for(@model_class)
      )

      redirect_to super_admin_exports_path,
                  notice: t("super_admin.exports.flash.created", token: export.token)
    end

    def download
      return unless @export
      unless @export.ready_for_download?
        redirect_to super_admin_exports_path,
                    alert: t("super_admin.exports.flash.unavailable")
        return
      end

      if @export.expires_at.present? && @export.expires_at.past?
        redirect_to super_admin_exports_path,
                    alert: t("super_admin.exports.flash.expired")
        return
      end

      send_data @export.file.download,
                filename: @export.file.filename.to_s,
                type: @export.file.content_type || "text/csv",
                disposition: "attachment"
    end

    def destroy
      return unless @export

      if active_storage_available?
        @export.destroy!
      else
        @export.delete
      end

      redirect_to super_admin_exports_path,
                  notice: t("super_admin.exports.flash.destroyed")
    end

    private

    def load_model_class
      @model_class = SuperAdmin::ModelInspector.find_model(params[:resource])

      return if @model_class

      redirect_to super_admin_root_path,
                  alert: t("super_admin.resources.flash.load_model_failed", resource: params[:resource])
    end

    def sanitized_filters(model_class, raw_filters)
      return {} if raw_filters.blank?

      filters_params = raw_filters.is_a?(ActionController::Parameters) ? raw_filters : ActionController::Parameters.new(raw_filters)
      permitted_keys = SuperAdmin::FilterBuilder.permitted_param_keys(model_class)
      filters_params.permit(*permitted_keys).to_unsafe_h
    end

    def find_export
      @export = current_user.csv_exports.find_by(token: params[:token])
      return if @export

      redirect_to super_admin_exports_path,
                  alert: t("super_admin.exports.flash.not_found")
    end

    def active_storage_available?
      return false unless defined?(ActiveStorage::Attachment)

      ActiveStorage::Attachment.table_exists?
    rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
      false
    end
  end
end
