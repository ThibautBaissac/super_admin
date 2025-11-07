# frozen_string_literal: true

module SuperAdmin
  # Service responsible for generating form fields
  # based on attribute type and model associations.
  class FormBuilder
    attr_reader :model_class, :form, :attribute_name, :column, :view_context

    def initialize(model_class:, form:, attribute_name:)
      @model_class = model_class
      @form = form
      @attribute_name = attribute_name.to_s
      @column = model_class.columns_hash[@attribute_name]
      @view_context = resolve_view_context
    end

    # Generates the appropriate form field
    # @return [String] HTML of the form field
    def build_field
      field.render
    end

    # Returns the field type
    # @return [Symbol]
    def field_type
      field.type
    end

    # Returns options for the field
    # @return [Hash]
    def field_options
      field.options
    end

    # Returns the label for the field
    # @return [String]
    def field_label
      field.label
    end

    protected

    def field
      @field ||= SuperAdmin::FormFields::Factory.build(self)
    end

    private

    def resolve_view_context
      template = form.instance_variable_get(:@template)
      return template if template

      context = form.instance_variable_get(:@view_context)
      return context if context

      raise ArgumentError, "SuperAdmin::FormBuilder requires an ActionView context"
    end
  end
end
