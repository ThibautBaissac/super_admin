# frozen_string_literal: true

module SuperAdmin
  # Persists a trace of meaningful operations executed through SuperAdmin.
  class AuditLog < ApplicationRecord
    self.table_name = "super_admin_audit_logs"

    belongs_to :user,
               class_name: SuperAdmin.configuration.user_class_constant.name,
               optional: true

  validates :resource_type, :action, :performed_at, presence: true

    scope :recent, -> { order(performed_at: :desc) }

    before_validation :default_performed_at
    before_validation :default_payloads

    private

    def default_performed_at
      return if performed_at.present?

      # When required attributes are missing, keep the field blank so validation errors surface.
      return if resource_type.blank? || action.blank?

      self.performed_at = Time.current
    end

    def default_payloads
      self.changes_snapshot ||= {}
      self.context ||= {}
    end
  end
end
