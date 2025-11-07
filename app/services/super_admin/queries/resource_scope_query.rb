# frozen_string_literal: true

module SuperAdmin
  module Queries
    # Orchestrator that composes query objects to build the complete scope.
    class ResourceScopeQuery
      LEGACY_ARGUMENT_ERROR = "ResourceScopeQuery expects an ActiveRecord::Relation or ActiveRecord::Base subclass".freeze

      attr_reader :model_class, :scope, :search, :sort_column, :direction, :filters

      # @param scope_or_model_class [ActiveRecord::Relation, Class]
      # @param search [String, nil]
      # @param query [String, nil] Legacy alias for +search+
      # @param sort [String, nil] Legacy alias for +sort_column+
      # @param sort_column [String, nil]
      # @param direction [String, nil]
      # @param sort_direction [String, nil] Legacy alias for +direction+
      # @param filters [Hash]
      def initialize(scope_or_model_class, search: nil, query: nil, sort: nil, sort_column: nil,
                     direction: nil, sort_direction: nil, filters: {})
        relation, klass = resolve_scope_and_class(scope_or_model_class)

        @scope = relation
        @model_class = klass
        @search = search.presence || query
        @sort_column = sort_column || sort
        @direction = direction || sort_direction
        @filters = filters || {}
      end

      # Builds the complete scope by composing query objects
      # @return [ActiveRecord::Relation]
      def call
        result = scope
        result = apply_search(result)
        result = apply_filters(result)
        apply_sort(result)
      end

      private

      # Applies full-text search
      # @param scope [ActiveRecord::Relation]
      # @return [ActiveRecord::Relation]
      def apply_search(scope)
        SearchQuery.new(scope, model_class, term: search).call
      end

      # Applies typed filters
      # @param scope [ActiveRecord::Relation]
      # @return [ActiveRecord::Relation]
      def apply_filters(scope)
        FilterQuery.new(scope, model_class, filters: filters).call
      end

      # Applies sorting
      # @param scope [ActiveRecord::Relation]
      # @return [ActiveRecord::Relation]
      def apply_sort(scope)
        SortQuery.new(scope, model_class, sort_column: sort_column, direction: direction).call
      end

      def resolve_scope_and_class(scope_or_model_class)
        if scope_or_model_class.is_a?(ActiveRecord::Relation)
          [ scope_or_model_class, scope_or_model_class.klass ]
        elsif scope_or_model_class.is_a?(Class) && scope_or_model_class < ActiveRecord::Base
          [ scope_or_model_class.all, scope_or_model_class ]
        else
          raise ArgumentError, LEGACY_ARGUMENT_ERROR
        end
      end
    end
  end
end
