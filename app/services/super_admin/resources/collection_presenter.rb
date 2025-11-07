# frozen_string_literal: true

module SuperAdmin
  module Resources
    # Provides helper methods to work with resource collections (filtering, exports, pagination state).
    class CollectionPresenter
      attr_reader :context, :params

      delegate :model_class, :resource_param, to: :context

      def initialize(context:, params:)
        @context = context
        @params = params
      end

      def filter_definitions
        SuperAdmin::FilterBuilder.definitions_for(model_class)
      end

      def filter_params
        @filter_params ||= FilterParams.new(model_class, params[:filters]).to_h
      end

      def scope
        @scope ||= begin
          base_scope = SuperAdmin::ResourceQuery.filtered_scope(
            model_class,
            search: params[:search],
            sort: params[:sort],
            direction: params[:direction],
            filters: filter_params
          )

          # Apply eager loading to avoid N+1 queries
          includes = SuperAdmin::DashboardResolver.collection_includes_for(model_class)
          includes.any? ? base_scope.includes(includes) : base_scope
        end
      end

      def preserved_params
        {}.tap do |hash|
          hash[:search] = params[:search] if params[:search].present?
          hash[:sort] = params[:sort] if params[:sort].present?
          hash[:direction] = params[:direction] if params[:direction].present?
          hash[:filters] = filter_params if filter_params.present?
        end
      end

      def queue_export!(user, attributes)
        SuperAdmin::CsvExportCreator.call(
          user: user,
          model_class: model_class,
          resource: resource_param,
          search: params[:search],
          sort: params[:sort],
          direction: params[:direction],
          filters: filter_params,
          attributes: attributes
        )
      end
    end
  end
end
