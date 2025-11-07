# frozen_string_literal: true

module SuperAdmin
  # Base application controller for SuperAdmin namespace.
  # Delegates authentication and layout decisions to configuration to ease gem extraction.
  class ApplicationController < SuperAdmin.configuration.parent_controller_constant
    layout -> { SuperAdmin.configuration.layout }

    helper SuperAdmin::ApplicationHelper

    before_action :authenticate_super_admin_user!, if: -> { SuperAdmin.configuration.authenticate_with.present? }
    around_action :with_super_admin_locale, if: -> { SuperAdmin.configuration.default_locale.present? }

    private

    def authenticate_super_admin_user!
      strategy = SuperAdmin.configuration.authenticate_with

      case strategy
      when Proc
        invoke_proc_strategy(strategy, self)
      when Symbol, String
        send(strategy)
      end
    end

    def with_super_admin_locale(&block)
      locale = SuperAdmin.configuration.default_locale || I18n.default_locale
      I18n.with_locale(locale, &block)
    end

    def current_user
      strategy = SuperAdmin.configuration.current_user_method

      case strategy
      when Proc
        result = invoke_proc_strategy(strategy, self)

        if result.nil?
          original_receiver = proc_original_receiver(strategy)
          if original_receiver && !original_receiver.equal?(self)
            begin
              alternate = invoke_proc_strategy(strategy, original_receiver)
              result = alternate unless alternate.nil?
            rescue NameError, NoMethodError
              # Ignore fallback errors; return the best effort result
            end
          end
        end

        return result unless result.nil?

        defined?(super) ? super : nil
      when Symbol, String
        strategy_name = strategy.to_sym

        if strategy_name == __method__
          defined?(super) ? super : nil
        elsif respond_to?(strategy_name, true)
          send(strategy_name)
        elsif defined?(super)
          super
        end
      else
        defined?(super) ? super : nil
      end
    end

    def invoke_proc_strategy(strategy, receiver)
      return unless strategy

      arity = strategy.arity

      if arity.zero?
        receiver.instance_exec(&strategy)
      else
        strategy.call(receiver)
      end
    rescue ArgumentError
      strategy.call(receiver)
    end

    def proc_original_receiver(strategy)
      strategy.binding.receiver
    rescue ArgumentError
      nil
    end
  end
end
