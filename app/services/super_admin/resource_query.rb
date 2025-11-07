# frozen_string_literal: true

module SuperAdmin
  # Builds ActiveRecord scopes for SuperAdmin resources (search, filters, sort).
  # Delegates logic to query objects for better separation of concerns.
  class ResourceQuery
    class << self
      # Returns the filtered scope ready for pagination/export.
      # @param model_class [Class]
      # @param search [String, nil]
      # @param sort [String, nil]
      # @param direction [String, nil]
      # @param filters [Hash]
      def filtered_scope(model_class, search:, sort:, direction:, filters: {})
        SuperAdmin::Queries::ResourceScopeQuery.new(
          model_class,
          search: search,
          sort_column: sort,
          direction: direction,
          filters: filters
        ).call
      end

      # DEPRECATED: Use SuperAdmin::Queries::SearchQuery directly
      def apply_search(scope, model_class, term)
        SuperAdmin::Queries::SearchQuery.new(scope, model_class, term: term).call
      end

      # DEPRECATED: Use SuperAdmin::Queries::SortQuery directly
      def apply_sort(scope, model_class, sort, direction)
        SuperAdmin::Queries::SortQuery.new(scope, model_class, sort_column: sort, direction: direction).call
      end

      # DEPRECATED: Method kept for compatibility but not used
      def association_search_predicates(model_class, patterns:, lower_pattern:)
        { predicates: [], associations: [] }
      end
    end
  end
end
