# frozen_string_literal: true

require "csv"
require "stringio"

module SuperAdmin
  # Generates a CSV export for a SuperAdmin resource respecting visible attributes.
  class ResourceExporter
    BATCH_SIZE = 1000

    def initialize(model_class, scope, attributes: nil)
      @model_class = model_class
      @scope = scope
      @attributes = attributes.presence || model_class.attribute_names
    end

    # Writes CSV content to a given IO (Tempfile, StringIO, etc.).
    # @param io [IO]
    def write_to(io)
      csv = CSV.new(io, headers: header_row, write_headers: true)
      export_scope.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        batch.each do |record|
          csv << data_row(record)
        end
        io.flush if io.respond_to?(:flush)
      end
    end

    # @return [String] contenu CSV avec en-têtes (utilisé principalement pour tests)
    def to_csv
      buffer = StringIO.new
      write_to(buffer)
      buffer.rewind
      buffer.read
    ensure
      buffer&.close
    end

    private

    attr_reader :model_class, :scope, :attributes

    def header_row
      attributes.map { |attr| model_class.human_attribute_name(attr) }
    end

    def data_row(record)
      attributes.map do |attr|
        value = record.public_send(attr)
        format_value(value)
      end
    end

    def export_scope
      relation = scope
      if relation.respond_to?(:except)
        relation = relation.except(:select, :includes, :preload, :eager_load)
      end
      relation = relation.reorder(nil) if relation.order_values.any?
      relation = relation.limit(nil) if relation.respond_to?(:limit)
      relation = relation.offset(nil) if relation.respond_to?(:offset)
      relation
    end

    def format_value(value)
      case value
      when nil
        ""
      when true, false
        value ? "true" : "false"
      when Time, Date, DateTime, ActiveSupport::TimeWithZone
        value.iso8601
      else
        value.to_s
      end
    end
  end
end
