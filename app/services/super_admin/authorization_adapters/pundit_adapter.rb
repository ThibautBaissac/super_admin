# frozen_string_literal: true

module SuperAdmin
  module AuthorizationAdapters
    # Adapter delegating authorization to Pundit.
    class PunditAdapter < BaseAdapter
      def authorized?(resource = nil)
        ensure_pundit_available!
        subject = resource || :super_admin
        controller.__send__(:authorize, subject, :access?)
        true
      rescue LoadError => exception
        raise SuperAdmin::ConfigurationError, missing_policy_message(exception)
      rescue StandardError => exception
        if pundit_not_authorized?(exception)
          return remember_failure(exception)
        end

        if policy_missing?(exception)
          raise SuperAdmin::ConfigurationError, missing_policy_message(exception)
        end

        raise
      end

      def authorized_scope(scope)
        ensure_pundit_available!
        return scope unless controller.respond_to?(:policy_scope)

        controller.policy_scope(scope)
      rescue LoadError => exception
        raise SuperAdmin::ConfigurationError, missing_policy_message(exception)
      rescue StandardError => exception
        if policy_missing?(exception)
          raise SuperAdmin::ConfigurationError, missing_policy_message(exception)
        end

        raise
      end

      def build_error
        error = SuperAdmin::Authorization::NotAuthorizedError.new(default_error_message)
        attach_cause(error)
        error
      end

      def handle_unauthorized!(error)
        redirect_with_alert!(error.message)
      end

      private

      def ensure_pundit_available!
        return if defined?(::Pundit)
        return if controller.respond_to?(:authorize)

        raise SuperAdmin::ConfigurationError, "Pundit adapter selected but Pundit is not loaded"
      end

      def pundit_not_authorized?(exception)
        defined?(::Pundit::NotAuthorizedError) && exception.is_a?(::Pundit::NotAuthorizedError)
      end

      def attach_cause(error)
        return unless last_exception

        cause = last_exception
        error.define_singleton_method(:cause) { cause }
        error.set_backtrace(cause.backtrace) if cause.backtrace
      end

      def missing_policy_message(exception)
        "SuperAdminPolicy with #access? must exist when using the Pundit adapter. #{exception.message}"
      end

      def policy_missing?(exception)
        defined?(::Pundit::NotDefinedError) && exception.is_a?(::Pundit::NotDefinedError)
      end
    end
  end
end
