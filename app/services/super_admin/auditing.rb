# frozen_string_literal: true

module SuperAdmin
  # Lightweight helper that records meaningful user actions inside SuperAdmin.
  module Auditing
    module_function

    def log!(user:, resource: nil, resource_type: nil, resource_id: nil, action:, changes: nil, context: {})
      resource_type ||= resource&.class&.name
      resource_id ||= resource&.try(:id)&.to_s

  return if resource_type.blank? || resource_type == "SuperAdmin::AuditLog"

      SuperAdmin::AuditLog.create(
        user: compatible_user(user),
        user_email: safe_user_email(user),
        resource_type: resource_type,
        resource_id: resource_id,
        action: action.to_s,
  changes_snapshot: prepare_changes(resource, action, changes),
        context: context.presence || {},
        performed_at: Time.current
      )
    rescue StandardError => error
      Rails.logger.error(
        "[SuperAdmin::Auditing] Failed to log action #{action} on #{resource.class.name}: #{error.class} - #{error.message}"
      )
      nil
    end

    def compatible_user(user)
      return nil unless user

      user_class = SuperAdmin.configuration.user_class_constant
      return user if user.is_a?(user_class)

      nil
    rescue SuperAdmin::ConfigurationError
      nil
    end

    def safe_user_email(user)
      user.respond_to?(:email) ? user.email : nil
    end

    def prepare_changes(resource, action, changes)
      payload = if changes.present?
        sanitize_changes(changes)
      else
        resource ? default_changes(resource, action) : {}
      end
      payload.presence || {}
    end

    def default_changes(resource, action)
      case action.to_s
      when "create"
        { "after" => resource.attributes }
      when "update"
        sanitize_changes(resource.previous_changes)
      when "destroy"
        { "before" => resource.attributes }
      else
        {}
      end
    end

    def sanitize_changes(changes)
      return {} unless changes

      changes.except("updated_at")
    end
  end
end
