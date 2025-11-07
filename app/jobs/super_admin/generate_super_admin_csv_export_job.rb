# frozen_string_literal: true

# Generates a CSV export in the background for SuperAdmin.
module SuperAdmin
  class GenerateSuperAdminCsvExportJob < ApplicationJob
    queue_as :default

    def perform(export_reference = nil, **options)
      export = nil
      args = normalize_arguments(export_reference, options)

      export = SuperAdmin::CsvExport.find(args.fetch(:export_id))
      export.mark_processing!

      model_class_name = args[:model_class_name] || export.model_class_name || export.resource_name.classify
      model_class = SuperAdmin::ModelInspector.find_model(model_class_name) || SuperAdmin::ModelInspector.find_model(export.resource_name)
      raise ActiveRecord::RecordNotFound, export.resource_name unless model_class

      scope = SuperAdmin::ResourceQuery.filtered_scope(
        model_class,
        search: export.search,
        sort: export.sort,
        direction: export.direction,
        filters: export.filters
      )

      if args[:scope_params].present? && scope.respond_to?(:merge)
        scope = scope.merge(model_class.where(args[:scope_params]))
      end

      records_count = scope.count

      exporter = SuperAdmin::ResourceExporter.new(
        model_class,
        scope,
        attributes: args[:attributes].presence || export.selected_attributes.presence || SuperAdmin::DashboardResolver.collection_attributes_for(model_class)
      )

  attach_csv(export, exporter)
      export.mark_ready!(records_count: records_count)
    rescue StandardError => error
      export_identifier = (args && args[:export_id]) || export&.id
      Rails.logger.error("[SuperAdmin::GenerateSuperAdminCsvExportJob] Export ##{export_identifier} failed: #{error.class} - #{error.message}")
      export&.mark_failed!(error.message)
      raise
    ensure
      cleanup_tempfile
    end

    private

    def normalize_arguments(export_reference, options)
      params =
        case export_reference
        when Hash
          export_reference
        when nil
          options
        else
          options.merge(export_id: export_reference)
        end

      params.to_h.transform_keys(&:to_sym)
    end

    def attach_csv(export, exporter)
      @tempfile = Tempfile.new([ export.resource_name, ".csv" ], binmode: true)
      exporter.write_to(@tempfile)
      @tempfile.rewind

      unless active_storage_available?
        Rails.logger.warn("[SuperAdmin::GenerateSuperAdminCsvExportJob] ActiveStorage tables missing; skipping CSV attach for export ##{export.id}")
        return
      end

      export.file.attach(
        io: @tempfile,
        filename: "#{export.resource_name}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.csv",
        content_type: "text/csv"
      )
    end

    def active_storage_available?
      return false unless defined?(ActiveStorage::Attachment)

      ActiveStorage::Attachment.table_exists? && ActiveStorage::Blob.table_exists?
    rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
      false
    end

    def cleanup_tempfile
      return unless defined?(@tempfile) && @tempfile

      @tempfile.close
      @tempfile.unlink
    rescue StandardError => error
      Rails.logger.warn("[SuperAdmin::GenerateSuperAdminCsvExportJob] Tempfile cleanup warning: #{error.message}")
    end
  end
end
