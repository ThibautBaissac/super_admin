# frozen_string_literal: true

module SuperAdmin
  # Service responsible for inspecting ActiveRecord models.
  # Extracts information about attributes, types, and associations.
  class ModelInspector
    # System models to exclude from SuperAdmin interface
    EXCLUDED_MODELS = %w[
      ApplicationRecord
      ActiveRecord::Base
      ActiveRecord::SchemaMigration
      ActiveRecord::InternalMetadata
      ActionText::Record
      ActionText::RichText
      ActionText::EncryptedRichText
      ActionMailbox::Record
      ActionMailbox::InboundEmail
      ActiveStorage::Record
      ActiveStorage::Blob
      ActiveStorage::Attachment
      ActiveStorage::VariantRecord
      SolidQueue::Job
      SolidQueue::Process
      SolidQueue::RecurringTask
      SolidQueue::ScheduledExecution
      SolidQueue::ReadyExecution
      SolidQueue::ClaimedExecution
      SolidQueue::FailedExecution
      SolidQueue::BlockedExecution
      SolidQueue::Semaphore
      SolidQueue::Pause
      SolidCable::Message
      SolidCache::Entry
    ].freeze

    class << self
      # Returns list of all administrable models
      # @return [Array<Class>] List of model classes
      def all_models
        Rails.application.eager_load! unless Rails.application.config.eager_load

        SuperAdmin::DashboardRegistry.instance.resource_classes
      end

      # Returns the list of models that could be managed by SuperAdmin, regardless of dashboard presence.
      # @return [Array<Class>]
      def discoverable_models
        Rails.application.eager_load! unless Rails.application.config.eager_load

        ActiveRecord::Base.descendants
          .reject { |model| excluded_model?(model) }
          .sort_by(&:name)
      end

      # Returns detailed information about a model
      # @param model_class [Class] The model class
      # @return [Hash] Model information
      def inspect_model(model_class)
        {
          name: model_class.name,
          table_name: model_class.table_name,
          human_name: model_class.model_name.human,
          attributes: inspect_attributes(model_class),
          associations: inspect_associations(model_class),
          validations: inspect_validations(model_class)
        }
      end

      # Returns model attributes with their metadata
      # @param model_class [Class] The model class
      # @return [Hash] Attributes with type, null, default, etc.
      def inspect_attributes(model_class)
        model_class.columns.each_with_object({}) do |column, hash|
          hash[column.name] = {
            type: column.type,
            sql_type: column.sql_type,
            null: column.null,
            default: column.default,
            limit: column.limit,
            precision: column.precision,
            scale: column.scale
          }
        end
      end

      # Returns model associations
      # @param model_class [Class] The model class
      # @return [Hash] Associations grouped by type
      def inspect_associations(model_class)
        model_class.reflect_on_all_associations.each_with_object({}) do |assoc, hash|
          hash[assoc.name] = {
            type: assoc.macro,
            class_name: assoc.class_name,
            foreign_key: assoc.foreign_key,
            primary_key: assoc.association_primary_key,
            polymorphic: assoc.polymorphic?,
            through: assoc.through_reflection&.name
          }
        end
      end

      # Returns model validations
      # @param model_class [Class] The model class
      # @return [Hash] Validations by attribute
      def inspect_validations(model_class)
        model_class.validators.each_with_object(Hash.new { |h, k| h[k] = [] }) do |validator, hash|
          validator.attributes.each do |attribute|
            hash[attribute] << {
              kind: validator.kind,
              options: validator.options.except(:class)
            }
          end
        end
      end

      # Checks if an attribute is an enum
      # @param model_class [Class] The model class
      # @param attribute_name [String, Symbol] The attribute name
      # @return [Boolean]
      def enum?(model_class, attribute_name)
        model_class.defined_enums.key?(attribute_name.to_s)
      end

      # Returns possible values for an enum
      # @param model_class [Class] The model class
      # @param attribute_name [String, Symbol] The attribute name
      # @return [Hash, nil] Hash of enum values or nil
      def enum_values(model_class, attribute_name)
        model_class.defined_enums[attribute_name.to_s]
      end

      # Finds a model class by its name
      # @param model_name [String] The model name (plural or singular)
      # @return [Class, nil] The model class or nil
      def find_model(model_name)
        name = model_name.to_s

        candidates = build_candidate_names(name)

        candidates.each do |candidate|
          klass = candidate.safe_constantize
          return klass if valid_model_class?(klass)
        end

        # Fallback to registered dashboard models
        normalized_name = name.singularize.camelize
        all_models.find { |m| m.name == normalized_name }
      end

      private

      def build_candidate_names(name)
        variations = [ name, name.singularize, name.pluralize ].uniq

        variations.flat_map do |variation|
          [ variation, variation.camelize, variation.singularize.camelize ]
        end.uniq
      end

      def valid_model_class?(klass)
        klass.is_a?(Class) && klass < ActiveRecord::Base && !klass.abstract_class?
      end

      # Checks if a model should be excluded
      # @param model [Class] The model class
      # @return [Boolean]
      def excluded_model?(model)
        return true if model.abstract_class?
        return true if EXCLUDED_MODELS.include?(model.name)
        return true if model.name.start_with?("ActiveRecord::", "ActionText::", "ActionMailbox::", "ActiveStorage::", "SolidQueue::", "SolidCable::", "SolidCache::")
        return true unless model.table_exists?

        false
      rescue StandardError => error
        Rails.logger.warn(
          "[SuperAdmin::ModelInspector] Failed to evaluate exclusion for #{model}: #{error.class} - #{error.message}"
        )
        true
      end
    end
  end
end
