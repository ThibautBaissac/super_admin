# frozen_string_literal: true

module SuperAdmin
  # Generic CRUD controller for all resources.
  # Uses ActiveRecord reflection to adapt dynamically to each model.
  class ResourcesController < SuperAdmin::BaseController
    before_action :load_resource_context
    before_action :set_resource, only: %i[show edit update destroy]

    # GET /super_admin/:resource
    def index
      collection = SuperAdmin::Resources::CollectionPresenter.new(context: @context, params: params)
      @filter_definitions = collection.filter_definitions
      @attributes = @context.displayable_attributes

      respond_to do |format|
        format.html do
          @applied_filters = collection.filter_params
          @pagy, @resources = pagy(collection.scope, limit: 25)
        end

        format.csv do
          export = collection.queue_export!(current_user, @attributes)

          flash[:notice] = t("super_admin.exports.flash.created", token: export.token)
          redirect_to super_admin_exports_path
        end
      end
    end

    # GET /super_admin/:resource/:id
    def show
      @attributes = @context.show_attributes
      @associations = @model_class.reflect_on_all_associations
      @association_counts = SuperAdmin::Resources::AssociationInspector.new(@resource).has_many_counts(@associations)
    end

    # GET /super_admin/:resource/new
    def new
      @resource = @model_class.new
      @editable_attributes = @context.editable_attributes
    end

    # POST /super_admin/:resource
    def create
      @resource = @model_class.new(resource_params)

      if @resource.save
        audit(:create, resource: @resource)
        redirect_to super_admin_resource_path(resource: params[:resource], id: @resource.id),
                    notice: t("super_admin.resources.flash.create.success", model: @model_class.model_name.human)
      else
        @editable_attributes = @context.editable_attributes
        render :new, status: :unprocessable_entity
      end
    end

    # GET /super_admin/:resource/:id/edit
    def edit
      @editable_attributes = @context.editable_attributes
    end

    # PATCH /super_admin/:resource/:id
    def update
      if @resource.update(resource_params)
        audit(:update, resource: @resource, changes: @resource.previous_changes)
        redirect_to super_admin_resource_path(resource: params[:resource], id: @resource.id),
                    notice: t("super_admin.resources.flash.update.success", model: @model_class.model_name.human)
      else
        @editable_attributes = @context.editable_attributes
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /super_admin/:resource/:id
    def destroy
      snapshot = @resource.attributes
      @resource.destroy!
      audit(
        :destroy,
        resource_type: @model_class.name,
        resource_id: snapshot[@model_class.primary_key]&.to_s,
        changes: { "before" => snapshot }
      )

      redirect_to super_admin_resources_path(resource: params[:resource]),
                  notice: t("super_admin.resources.flash.destroy.success", model: @model_class.model_name.human)
    rescue ActiveRecord::InvalidForeignKey, ActiveRecord::DeleteRestrictionError
      redirect_to super_admin_resource_path(resource: params[:resource], id: @resource.id),
                  alert: t("super_admin.resources.flash.destroy.dependencies")
    end

    # POST /super_admin/:resource/bulk
    def bulk
      collection = SuperAdmin::Resources::CollectionPresenter.new(context: @context, params: params)
      selection = bulk_params[:resource_ids]&.reject(&:blank?) || []
      action = bulk_params[:bulk_action]

      if selection.empty?
        redirect_to super_admin_resources_path(resource: params[:resource], **collection.preserved_params),
                    alert: t("super_admin.resources.flash.bulk.selection_required")
        return
      end

      case action
      when "destroy"
        records = @model_class.where(id: selection)
        destroyed_count = records.size
        @model_class.transaction do
          records.find_each do |record|
            snapshot = record.attributes
            record.destroy!
            audit(
              :destroy,
              resource_type: @model_class.name,
              resource_id: snapshot[@model_class.primary_key]&.to_s,
              changes: { "before" => snapshot, "bulk" => true, "selection" => selection }
            )
          end
        end
        redirect_to super_admin_resources_path(resource: params[:resource], **collection.preserved_params),
                    notice: t("super_admin.resources.flash.bulk.success", count: destroyed_count, model: @model_class.model_name.human(count: destroyed_count))
      else
        redirect_to super_admin_resources_path(resource: params[:resource], **collection.preserved_params),
                    alert: t("super_admin.resources.flash.bulk.unsupported_action")
      end
    rescue ActiveRecord::InvalidForeignKey, ActiveRecord::DeleteRestrictionError
      redirect_to super_admin_resources_path(resource: params[:resource], **collection.preserved_params),
                  alert: t("super_admin.resources.flash.bulk.dependencies")
    end

    private

    def load_resource_context
      @context = SuperAdmin::Resources::Context.new(params[:resource])
      @model_class = @context.model_class

      return if @context.valid?

      flash[:alert] = t("super_admin.resources.flash.load_model_failed", resource: params[:resource])
      redirect_to super_admin_root_path
      request.halt if request.respond_to?(:halt)
    end

    def set_resource
      relation = @model_class
      if action_name == "show"
        # Use dashboard-configured includes or fall back to AssociationInspector
        includes = SuperAdmin::DashboardResolver.show_includes_for(@model_class)
        if includes.empty?
          includes = SuperAdmin::Resources::AssociationInspector.preloadable_names(@model_class)
        end
        relation = relation.includes(includes) if includes.any?
      end

      @resource = relation.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = t("super_admin.resources.flash.not_found", model: @model_class.model_name.human)
      redirect_to super_admin_resources_path(resource: params[:resource])
    end

    def bulk_params
      params.permit(:bulk_action, resource_ids: [])
    end

    # Dynamic strong parameters based on model attributes and nested attributes
    def resource_params
      permitted = SuperAdmin::Resources::PermittedAttributes.new(@model_class).permit(params)
      SuperAdmin::Resources::ValueNormalizer.new(@model_class, permitted).normalize
    end

    def audit(action, resource: nil, resource_type: nil, resource_id: nil, changes: nil)
      return unless auditable?

      SuperAdmin::Auditing.log!(
        user: current_user,
        resource: resource,
        resource_type: resource_type,
        resource_id: resource_id,
        action: action,
        changes: changes,
        context: audit_context
      )
    end

    def auditable?
      @model_class.present? && @model_class.name != "SuperAdmin::AuditLog"
    end

    def audit_context
      {
        "resource" => params[:resource],
        "resource_id" => params[:id],
        "request_path" => request.fullpath,
        "request_id" => request.request_id,
        "controller" => controller_name,
        "action" => action_name
      }.compact
    end
  end
end
