# frozen_string_literal: true

module SuperAdmin
  module AuthorizationAdapters
    # Adapter executing a custom callable configured via SuperAdmin.configure { |c| c.authorize_with = ... }.
    class ProcAdapter < BaseAdapter
      def authorized?(resource = nil)
        callable = SuperAdmin.configuration.authorize_with
        raise SuperAdmin::ConfigurationError, "authorize_with must be a callable or method name" if callable.blank?

        result = case callable
        when Proc
          invoke_proc(callable, resource)
        when Symbol, String
          invoke_method(callable.to_sym)
        else
          raise SuperAdmin::ConfigurationError, "Unsupported authorize_with value: #{callable.inspect}"
        end

        !!result
      rescue SuperAdmin::ConfigurationError
        raise
      rescue StandardError => exception
        remember_failure(exception)
      end

      def build_error
        message = if last_exception&.respond_to?(:message) && last_exception.message.present?
          last_exception.message
        else
          default_error_message
        end

        SuperAdmin::Authorization::NotAuthorizedError.new(message)
      end

      def handle_unauthorized!(error)
        redirect_with_alert!(error.message)
      end

      private

      def invoke_proc(callable, resource)
        positional_count = callable.parameters.count { |type, _| %i[req opt].include?(type) }
        rest_parameter = callable.parameters.any? { |type, _| type == :rest }

        base_arguments = [ controller, resource, current_user ]
        args = base_arguments.first(positional_count)
        args += base_arguments.drop(positional_count) if rest_parameter

        controller.instance_exec(*args, &callable)
      end

      def invoke_method(method_name)
        if controller.respond_to?(method_name, true)
          controller.__send__(method_name)
        elsif current_user&.respond_to?(method_name)
          current_user.public_send(method_name)
        else
          raise SuperAdmin::ConfigurationError, "authorize_with method '#{method_name}' is not defined"
        end
      end
    end
  end
end
