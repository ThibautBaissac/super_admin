# frozen_string_literal: true

module SuperAdmin
  # Encapsulates CSV export creation logic and enqueues it in Solid Queue.
  class CsvExportCreator
    DEFAULT_RETENTION = 7.days

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(user:, model_class:, resource_name: nil, resource: nil, scope: nil, search: nil, sort: nil, direction: nil, filters: {}, attributes: [])
      @user = user
      @model_class = model_class
      @resource_name = (resource || resource_name || model_class.model_name.plural).to_s
      @scope = scope || model_class.all
      @search = search
      @sort = sort
      @direction = direction
      @filters = filters || {}
      @attributes = Array(attributes).map(&:to_s)
    end

    def call
      export = @user.csv_exports.create!(
        model_class_name: @model_class.name,
        resource_name: @resource_name,
        search: @search,
        sort: @sort,
        direction: @direction,
        filters: @filters,
        selected_attributes: @attributes,
        expires_at: DEFAULT_RETENTION.from_now
      )

      SuperAdmin::GenerateSuperAdminCsvExportJob.perform_later(
        export_id: export.id,
        model_class_name: @model_class.name,
        attributes: @attributes
      )

      export
    end
  end
end
