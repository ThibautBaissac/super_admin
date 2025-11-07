# frozen_string_literal: true

module SuperAdmin
  module Resources
    # Provides helpers around ActiveRecord associations for SuperAdmin screens.
    class AssociationInspector
      class << self
        def preloadable_names(model_class)
          model_class.reflect_on_all_associations.filter_map do |association|
            next unless %i[belongs_to has_one].include?(association.macro)
            options = association.options || {}
            next if options[:polymorphic] || options[:through]

            association.name
          end
        end
      end

      def initialize(resource)
        @resource = resource
      end

      def has_many_counts(associations)
        has_many_assocs = associations.select { |assoc| assoc.macro == :has_many }
        return {} if has_many_assocs.empty?

        # Optimize: use counter_cache when available, batch count for others
        counts = {}
        to_query = []

        has_many_assocs.each do |association|
          counter_method = "#{association.name}_count"
          if @resource.respond_to?(counter_method)
            # Use counter_cache column if available (no query)
            counts[association.name] = @resource.public_send(counter_method)
          else
            to_query << association
          end
        end

        # Batch count remaining associations to reduce queries
        if to_query.any?
          batch_counts = batch_count_associations(to_query)
          counts.merge!(batch_counts)
        end

        counts
      rescue StandardError => error
        Rails.logger.warn(
          "[SuperAdmin::Resources::AssociationInspector] Failed to count associations for #{@resource.class}##{@resource.id}: #{error.class} - #{error.message}"
        )
        has_many_assocs.each_with_object({}) { |assoc, h| h[assoc.name] = 0 }
      end

      private

      # Batch count multiple associations in parallel to reduce total queries
      # Falls back to individual counts if batch counting fails
      def batch_count_associations(associations)
        # For small numbers of associations (1-2), individual queries are fine
        return individual_counts(associations) if associations.size <= 2

        # Try batch counting with concurrent queries
        results = {}
        threads = associations.map do |association|
          Thread.new do
            begin
              count = count_for(association)
              [ association.name, count ]
            rescue StandardError => error
              Rails.logger.debug(
                "[SuperAdmin::AssociationInspector] Failed to count #{association.name}: #{error.message}"
              )
              [ association.name, 0 ]
            end
          end
        end

        threads.each do |thread|
          name, count = thread.value
          results[name] = count
        end

        results
      rescue StandardError
        # Fallback to individual counts if threading fails
        individual_counts(associations)
      end

      def individual_counts(associations)
        associations.each_with_object({}) do |association, counts|
          counts[association.name] = count_for(association)
        rescue StandardError
          counts[association.name] = 0
        end
      end

      def count_for(association)
        association_proxy = @resource.association(association.name)
        scope = association_proxy.scope

        # Clean up scope to get a simple count
        scope = scope.except(:select) if scope.respond_to?(:except)
        scope = scope.unscope(:order) if scope.respond_to?(:unscope)
        scope = scope.limit(nil) if scope.respond_to?(:limit)
        scope = scope.offset(nil) if scope.respond_to?(:offset)

        scope.count
      end
    end
  end
end
