# frozen_string_literal: true

module SuperAdmin
  module AuthorizationAdapters
    # Base class for authorization adapters. Provides helpers shared by all adapters.
    class BaseAdapter
      attr_reader :controller, :last_exception

      def initialize(controller)
        @controller = controller
        @last_exception = nil
      end

      def authorized?(resource = nil)
        raise NotImplementedError, "Adapters must implement #authorized?"
      end

      def authorize(resource = nil)
        @last_exception = nil

        result = invoke_authorized_check(resource)
        !!result
      rescue SuperAdmin::Authorization::NotAuthorizedError => error
        remember_failure(error)
        false
      rescue StandardError => error
        remember_failure(error)
        raise
      end

      def authorized_scope(scope)
        scope
      end

      # Default unauthorized handler simply raises the provided error. Adapters can override.
      def handle_unauthorized!(error)
        raise(error)
      end

      def build_error
        SuperAdmin::Authorization::NotAuthorizedError.new(default_error_message)
      end

      protected

      def remember_failure(exception = nil)
        @last_exception = exception
        false
      end

      def invoke_authorized_check(resource)
        method = method(:authorized?)

        if method.arity.zero?
          authorized?
        else
          authorized?(resource)
        end
      end

      def current_user
        strategy = SuperAdmin.configuration.current_user_method || :current_user

        case strategy
        when Proc
          controller.instance_exec(&strategy)
        when Symbol, String
          method_name = strategy.to_sym
          return unless controller.respond_to?(method_name, true)

          controller.__send__(method_name)
        else
          nil
        end
      rescue NoMethodError
        nil
      end

      def default_error_message
        I18n.t("super_admin.flash.access_denied", default: "You do not have permission to access this section.")
      end

      def redirect_with_alert!(message)
        return unless controller.respond_to?(:redirect_to)

        if controller.respond_to?(:flash)
          controller.flash[:alert] ||= message
        end

        target = if controller.respond_to?(:main_app) && controller.main_app.respond_to?(:root_path)
          controller.main_app.root_path
        else
          "/"
        end

        controller.redirect_to(target)
      end
    end
  end
end
