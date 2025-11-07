# frozen_string_literal: true

module SuperAdmin
  module Resources
    # Sanitizes filter parameters for a resource collection.
    class FilterParams
      def initialize(model_class, raw_filters)
        @model_class = model_class
        @raw_filters = raw_filters
      end

      def to_h
        return {} if @raw_filters.blank?

        parameters = ensure_parameters(@raw_filters)
        permitted_keys = SuperAdmin::FilterBuilder.permitted_param_keys(@model_class)
        parameters.permit(*permitted_keys).to_h
      end

      private

      def ensure_parameters(filters)
        return filters if filters.is_a?(ActionController::Parameters)

        ActionController::Parameters.new(filters)
      end
    end
  end
end
