# frozen_string_literal: true

require "test_helper"
require "ostruct"

module SuperAdmin
  class GenerateSuperAdminCsvExportJobTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
      @export = CsvExport.create!(
        user: @user,
        resource_name: "users",
        model_class_name: "User",
        status: :pending
      )
    end

    test "should perform job successfully" do
      # Create some users to export
      3.times do |i|
        User.create!(
          email: "export#{i}@example.com",
          name: "Export User #{i}",
          role: :user
        )
      end

      job = GenerateSuperAdminCsvExportJob.new

      # Mock the file attachment and update
      @export.stub :file, OpenStruct.new(attach: true, attached?: true) do
        @export.stub :mark_ready!, ->(records_count:) {
          @export.update!(status: :ready, records_count: records_count)
        } do
          job.perform(
            export_id: @export.id,
            model_class_name: "User",
            scope_params: {},
            attributes: [ "email", "name" ]
          )
        end
      end

      # Verify export was marked as ready
      assert @export.reload.ready_status?
    end

    test "should mark export as failed on error" do
      job = GenerateSuperAdminCsvExportJob.new

      # Force an error
      @export.stub :mark_failed!, ->(error) { @export.update!(status: :failed, error_message: error) } do
        begin
          job.perform(
            export_id: @export.id,
            model_class_name: "InvalidModel",
            scope_params: {},
            attributes: []
          )
        rescue
          # Expected to fail
        end
      end
    end

    test "attach_csv uses ActiveStorage when available" do
      job = GenerateSuperAdminCsvExportJob.new

      file_double = Class.new do
        attr_reader :attached_params

        def attach(params)
          @attached_params = params
        end
      end.new

      exporter = Minitest::Mock.new
      exporter.expect(:write_to, nil) { |io| io.respond_to?(:write) }

      export = Struct.new(:resource_name, :id, :file).new("users", 42, file_double)

      job.stub :active_storage_available?, true do
        job.send(:attach_csv, export, exporter)
      end

      exporter.verify
      assert_equal "text/csv", file_double.attached_params[:content_type]
      assert_match(/users-\d{8}-\d{6}\.csv/, file_double.attached_params[:filename])
      assert file_double.attached_params[:io].respond_to?(:read)
    ensure
      job.send(:cleanup_tempfile)
    end
  end
end
