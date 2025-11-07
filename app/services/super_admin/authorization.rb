# frozen_string_literal: true

module SuperAdmin
  # Authorization orchestrator. Selects the appropriate adapter and executes it.
  class Authorization
    class NotAuthorizedError < StandardError; end

    class << self
      def call(controller)
        adapter = build_adapter(controller)
        return true if adapter.authorized?

        handle_unauthorized(controller, adapter)
        false
      end

      def build_adapter(controller)
        resolve_adapter(controller).new(controller)
      end

      private

      def resolve_adapter(controller)
        adapter_option = SuperAdmin.configuration.authorization_adapter

        case adapter_option
        when nil, :auto
          auto_detect_adapter(controller)
        when :default
          config = SuperAdmin.configuration
          config.authorize_with.present? ? AuthorizationAdapters::ProcAdapter : AuthorizationAdapters::DefaultAdapter
        when Symbol, String
          adapter_from_name(adapter_option)
        when Class
          adapter_option
        else
          AuthorizationAdapters::DefaultAdapter
        end
      rescue NameError => e
        Rails.logger.error("[SuperAdmin] Authorization adapter resolution failed: #{e.message}")
        AuthorizationAdapters::DefaultAdapter
      end

      def auto_detect_adapter(controller)
        config = SuperAdmin.configuration

        return AuthorizationAdapters::ProcAdapter if config.authorize_with.present?

        if defined?(::Pundit) && controller.respond_to?(:authorize, true)
          return AuthorizationAdapters::PunditAdapter
        end

        if defined?(::CanCan::Ability) && controller.respond_to?(:authorize!, true)
          return AuthorizationAdapters::CancanAdapter
        end

        AuthorizationAdapters::DefaultAdapter
      end

      def adapter_from_name(name)
        key = name.to_sym

        case key
        when :pundit
          AuthorizationAdapters::PunditAdapter
        when :cancan, :cancancan
          AuthorizationAdapters::CancanAdapter
        when :proc
          AuthorizationAdapters::ProcAdapter
        when :default
          AuthorizationAdapters::DefaultAdapter
        else
          "SuperAdmin::AuthorizationAdapters::#{key.to_s.camelize}Adapter".constantize
        end
      end

      def handle_unauthorized(controller, adapter)
        handler = SuperAdmin.configuration.on_unauthorized
        error = adapter.build_error

        if handler
          invoke_handler(controller, error, handler)
        else
          adapter.handle_unauthorized!(error)
        end

        error
      end

      def invoke_handler(controller, error, handler)
        case handler
        when Proc
          args = case handler.arity
          when 0
            []
          when 1
            [ error ]
          else
            [ controller, error ]
          end

          controller.instance_exec(*args, &handler)
        else
          if controller.respond_to?(handler)
            controller.public_send(handler, error)
          else
            raise ConfigurationError, "Unauthorized handler '#{handler}' is not defined"
          end
        end
      end
    end
  end
end
