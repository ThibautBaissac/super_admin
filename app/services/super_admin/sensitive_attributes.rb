# frozen_string_literal: true

module SuperAdmin
  module SensitiveAttributes
    DEFAULT_SENSITIVE_PATTERNS = %w[
      password
      password_digest
      password_confirmation
      encrypted_password
      reset_password_token
      reset_password_sent_at
      remember_token
      remember_created_at
      authentication_token
      access_token
      refresh_token
      api_key
      api_secret
  token
      secret
      secret_key
      secret_token
      private_key
      otp_secret
      otp_secret_key
      encrypted_otp_secret
      encrypted_otp_secret_iv
      encrypted_otp_secret_salt
      confirmation_token
      confirmed_at
      confirmation_sent_at
      unconfirmed_email
      unlock_token
      locked_at
      failed_attempts
      encrypted_
      crypted_
      cipher_
    ].freeze

    DEFAULT_ROLE_PATTERNS = %w[
      admin
      superadmin
      super_admin
      role
      roles
      permission
      permissions
      can_
      is_admin
      is_superadmin
    ].freeze

    DEFAULT_SYSTEM_PATTERNS = %w[
      created_at
      updated_at
      deleted_at
      discarded_at
      lock_version
    ].freeze

    class << self
      def default_patterns
        @default_patterns ||= (
          DEFAULT_SENSITIVE_PATTERNS +
          DEFAULT_ROLE_PATTERNS +
          DEFAULT_SYSTEM_PATTERNS
        ).map { |pattern| pattern.to_s.downcase }.freeze
      end

      def configured_patterns
        @configured_patterns ||= begin
          custom = Array(SuperAdmin.configuration.additional_sensitive_attributes)
                    .map { |pattern| pattern.to_s.downcase }

          (default_patterns + custom).uniq.freeze
        end
      end

      def sensitive?(attribute_name)
        attr_str = attribute_name.to_s.downcase

        configured_patterns.any? do |pattern|
          if pattern.end_with?("_")
            attr_str.start_with?(pattern)
          else
            attr_str == pattern ||
              attr_str.start_with?("#{pattern}_") ||
              attr_str.end_with?("_#{pattern}") ||
              attr_str.include?("_#{pattern}_")
          end
        end
      end

      def filter(attributes, model_class: nil, allowlist: [])
        case attributes
        when Hash
          filter_hash(attributes)
        when Array
          filter_attribute_array(attributes, model_class: model_class, allowlist: allowlist)
        else
          filter_attribute_array(Array(attributes), model_class: model_class, allowlist: allowlist)
        end
      end

      def reset!
        @default_patterns = nil
        @configured_patterns = nil
      end

      private

      def filter_hash(payload)
        payload.each_with_object({}) do |(key, value), result|
          result_key = preserve_key_type(key)

          result[result_key] = case value
          when Hash
                                 filter_hash(value)
          when Array
                                 value.map { |entry| entry.is_a?(Hash) ? filter_hash(entry) : filtered_value(result_key, entry) }
          else
                                 filtered_value(result_key, value)
          end
        end
      end

      def filter_attribute_array(attributes, model_class:, allowlist: [])
        allowed = Array(allowlist).map { |attr| to_symbol(attr) }.compact

        attributes.each_with_object([]) do |attr, result|
          case attr
          when Hash
            filtered_hash = attr.each_with_object({}) do |(key, value), memo|
              memo[to_symbol(key)] = filter_attribute_array(Array(value), model_class: model_class, allowlist: [])
            end
            result << filtered_hash
          else
            attr_sym = to_symbol(attr)
            next if attr_sym.nil?

            if allowed.include?(attr_sym) || !sensitive?(attr_sym)
              result << attr_sym
            elsif model_class
              Rails.logger.debug(
                "[SuperAdmin::SensitiveAttributes] Filtered sensitive attribute '#{attr_sym}' from #{model_class.name} permitted parameters"
              )
            end
          end
        end
      end

      def filtered_value(key, value)
        sensitive?(key) ? "[FILTERED]" : value
      end

      def preserve_key_type(key)
        key.is_a?(String) ? key : to_symbol(key)
      end

      def to_symbol(key)
        key.to_sym if key.respond_to?(:to_sym)
      end
    end
  end
end
