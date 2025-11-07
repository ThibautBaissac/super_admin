# frozen_string_literal: true

module SuperAdmin
  module AuthorizationAdapters
    # Fallback authorization strategy relying on configured super admin predicate.
    class DefaultAdapter < BaseAdapter
      def authorized?(resource = nil)
        checker = SuperAdmin.configuration.super_admin_check

        if checker
          user = current_user || resource
          raise SuperAdmin::ConfigurationError, "Configure a #current_user method or provide a user resource" unless user

          !!evaluate_custom_check(user, resource)
        else
          user = current_user || resource

          if user && (user.respond_to?(:super_admin?) || user.respond_to?(:admin?))
            !!evaluate_standard_predicate(user)
          else
            true
          end
        end
      rescue SuperAdmin::ConfigurationError => error
        raise error
      rescue StandardError => error
        raise SuperAdmin::ConfigurationError, "SuperAdmin authorization failed: #{error.message}"
      end

      def handle_unauthorized!(error)
        redirect_with_alert!(error.message)
      end

      private

      def evaluate_custom_check(user, resource)
        checker = SuperAdmin.configuration.super_admin_check

        case checker
        when Proc
          case checker.arity
          when 0
            controller.instance_exec(&checker)
          when 1
            controller.instance_exec(user, &checker)
          when 2
            controller.instance_exec(controller, user, &checker)
          else
            controller.instance_exec(controller, user, resource, &checker)
          end
        when Symbol, String
          predicate = checker.to_sym

          if user.respond_to?(predicate)
            user.public_send(predicate)
          elsif controller.respond_to?(predicate, true)
            controller.__send__(predicate, user)
          else
            raise SuperAdmin::ConfigurationError, "SuperAdmin predicate '#{predicate}' is not defined"
          end
        else
          raise SuperAdmin::ConfigurationError, "Unsupported super_admin_check: #{checker.inspect}"
        end
      end

      def evaluate_standard_predicate(user)
        if user.respond_to?(:super_admin?)
          user.super_admin?
        elsif user.respond_to?(:admin?)
          user.admin?
        else
          raise SuperAdmin::ConfigurationError, "Define SuperAdmin.super_admin_check or add #super_admin?/#admin? predicate to the user"
        end
      end
    end
  end
end
