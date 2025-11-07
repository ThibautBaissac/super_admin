# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

module SuperAdmin
  class Configuration
    attr_accessor :max_nested_depth,
                  :association_select_limit,
                  :association_pagination_limit,
                  :enable_association_search,
                  :authorization_adapter,
                  :on_unauthorized,
                  :current_user_method,
                  :layout,
                  :default_locale,
                  :parent_controller,
                  :user_class,
                  :super_admin_check

    attr_reader :authorize_with, :authenticate_with

    attr_reader :additional_sensitive_attributes

    def initialize
      @max_nested_depth = 2
      @association_select_limit = 10
      @association_pagination_limit = 20
      @enable_association_search = true

      @authorize_with = nil
      @authorization_adapter = :auto
      @on_unauthorized = nil

      @authenticate_with = nil
      @current_user_method = :current_user
      @user_class = "User"

      @layout = "super_admin"
      @default_locale = :fr
      @parent_controller = "::ApplicationController"

      @super_admin_check = nil
      @additional_sensitive_attributes = []
    end

    def authorize_with(value = nil, &block)
      if block_given?
        @authorize_with = block
      elsif !value.nil?
        @authorize_with = value
      else
        @authorize_with
      end
    end

    def authorize_with=(value)
      @authorize_with = value
    end

    def authenticate_with(value = nil, &block)
      if block_given?
        @authenticate_with = block
      elsif !value.nil?
        @authenticate_with = value
      else
        @authenticate_with
      end
    end

    def authenticate_with=(value)
      @authenticate_with = value
    end

    def additional_sensitive_attributes=(value)
      @additional_sensitive_attributes = Array(value)
      SuperAdmin::SensitiveAttributes.reset!
    end

    def user_class_constant
      user_class.is_a?(String) ? user_class.constantize : user_class
    rescue NameError
      raise ConfigurationError, "User class '#{user_class}' is not defined"
    end

    def parent_controller_constant
      parent_controller.is_a?(String) ? parent_controller.constantize : parent_controller
    rescue NameError
      raise ConfigurationError, "Parent controller '#{parent_controller}' is not defined"
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
      SuperAdmin::SensitiveAttributes.reset!
    end

    delegate :max_nested_depth,
             :association_select_limit,
             :association_pagination_limit,
             to: :configuration

    def enable_association_search?
      configuration.enable_association_search
    end
  end
end
