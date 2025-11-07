# frozen_string_literal: true

module SuperAdmin
  # Provides configuration helpers for models managed in SuperAdmin.
  class ResourceConfiguration
    DISPLAY_EXCLUDED_ATTRIBUTES = %w[created_at updated_at].freeze
    EDIT_EXCLUDED_ATTRIBUTES = %w[id created_at updated_at].freeze
    SENSITIVE_ATTRIBUTES = %w[
      encrypted_password
      reset_password_token
      reset_password_sent_at
      remember_created_at
      confirmation_token
      confirmation_sent_at
      unconfirmed_email
      unlock_token
      locked_at
      invitation_token
      invitation_sent_at
      invitation_accepted_at
      invitation_message
      authentication_token
      access_token
      refresh_token
      api_key
    ].freeze
    PRIORITY_ATTRIBUTES = %w[id email name title full_name first_name last_name].freeze

    class << self
      # Returns the list of displayable attributes for a resource.
      # @param model_class [Class]
      # @return [Array<String>]
      def displayable_attributes(model_class)
        base_attributes = model_class.attribute_names.reject do |attr|
          DISPLAY_EXCLUDED_ATTRIBUTES.include?(attr) || SENSITIVE_ATTRIBUTES.include?(attr)
        end

        prioritized = PRIORITY_ATTRIBUTES.compact.select do |attr|
          base_attributes.include?(attr) || attr == model_class.primary_key
        end

        (prioritized + base_attributes).uniq
      end

      # Returns the list of editable attributes (used by dynamic forms).
      # @param model_class [Class]
      # @return [Array<String>]
      def editable_attributes(model_class)
        base_attributes = model_class.attribute_names.reject do |attr|
          EDIT_EXCLUDED_ATTRIBUTES.include?(attr) || SENSITIVE_ATTRIBUTES.include?(attr)
        end

        nested_attributes = if model_class.respond_to?(:nested_attributes_options)
          model_class.nested_attributes_options.keys.map { |name| "#{name}_attributes" }
        else
          []
        end

        (base_attributes + nested_attributes).uniq
      end
    end
  end
end
