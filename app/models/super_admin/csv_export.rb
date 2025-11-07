# frozen_string_literal: true

module SuperAdmin
  class CsvExport < ApplicationRecord
    self.table_name = "super_admin_csv_exports"

    RETENTION_PERIOD = 7.days unless const_defined?(:RETENTION_PERIOD)

    belongs_to :user

    has_one_attached :file

    enum :status, {
      pending: "pending",
      processing: "processing",
      ready: "ready",
      failed: "failed"
    }, suffix: true

    validates :resource_name, :model_class_name, :status, :token, presence: true
    validates :token, uniqueness: true

    before_validation :generate_token, on: :create

    scope :recent_first, -> { order(created_at: :desc) }
    scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

    def ready_for_download?
      ready_status? && file.attached?
    rescue NoMethodError, ActiveRecord::StatementInvalid
      # Handle cases where ActiveStorage is unavailable or not initialized
      false
    end

    def mark_processing!
      update!(status: :processing, started_at: Time.current)
    end

    def mark_ready!(records_count:)
      update!(
        status: :ready,
        records_count: records_count,
        completed_at: Time.current,
        expires_at: RETENTION_PERIOD.from_now
      )
    end

    def mark_failed!(error_message)
      update!(
        status: :failed,
        error_message: error_message.to_s.truncate(500),
        completed_at: Time.current
      )
    end

    private

    # Generate a secure random token. The uniqueness validation and database unique index
    # will prevent race conditions. With 24 bytes (192 bits), the collision probability
    # is astronomically low (~1 in 10^57 for billions of records).
    def generate_token
      return if token.present?

      self.token = SecureRandom.urlsafe_base64(24)
    end
  end
end
