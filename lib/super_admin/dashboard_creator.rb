# frozen_string_literal: true

require "fileutils"
require "pathname"
require "active_support/inflector"

module SuperAdmin
  # Utility object responsible for creating dashboard skeleton files.
  class DashboardCreator
    def self.call(model_name: nil, stdout: $stdout)
      new(model_name:, stdout:).call
    end

    def initialize(model_name:, stdout:)
      @model_name = model_name
      @stdout = stdout
    end

    def call
      models = determine_models

      if models.empty?
        stdout.puts "No models found to generate dashboards for."
        return { generated: [], skipped: [] }
      end

      generated = []
      skipped = []

      models.each do |model|
        unless constantizable_model?(model)
          stdout.puts "Skipping #{model.inspect}: model is not constantizable."
          next
        end

        result = generate_dashboard(model)
        next unless result

        case result[:status]
        when :generated
          generated << result[:path]
        when :skipped
          skipped << result[:path]
        end
      end

      print_summary(generated, skipped)

      { generated:, skipped: }
    end

    private

    attr_reader :model_name, :stdout

    def determine_models
      models = if model_name && !model_name.to_s.strip.empty?
        [ resolve_model(model_name) ]
      else
        SuperAdmin::ModelInspector.discoverable_models
      end

      Array(models).compact.each_with_object([]) do |model, list|
        if engine_owned_model?(model)
          stdout.puts "Skipping #{model.name}: managed internally by SuperAdmin."
          next
        end

        list << model
      end
    end

    def constantizable_model?(model)
      return false unless model.respond_to?(:name)
      name = model.name
      return false if name.nil? || name.empty?

      constant = name.safe_constantize
      constant == model
    end

    def resolve_model(name)
      return name if name.is_a?(Class) && name < ActiveRecord::Base

      constant_name = normalize_model_name(name)
      klass = constant_name.constantize
      if engine_owned_model?(klass)
        raise ArgumentError, "#{constant_name} is managed internally by SuperAdmin and should not receive a dashboard."
      end
      return klass if klass < ActiveRecord::Base

      raise ArgumentError, "#{constant_name} is not an ActiveRecord model"
    rescue NameError
      raise ArgumentError, "Unable to find model for '#{name}'"
    end

    def normalize_model_name(name)
      raw = name.to_s.tr("/", "::").split("::").reject(&:empty?)
      segments = raw.map { |segment| segment.underscore.singularize.camelize }
      segments.join("::")
    end

    def generate_dashboard(model_class)
      if dashboard_exists?(model_class)
        stdout.puts "Skipping #{model_class.name}: dashboard already exists."
        return { status: :skipped, path: relative_dashboard_path(model_class).to_s }
      end

      path = absolute_dashboard_path(model_class)
      FileUtils.mkdir_p(path.dirname)
      File.write(path, dashboard_template(model_class))
      stdout.puts "Created #{relative_dashboard_path(model_class)}"

      { status: :generated, path: relative_dashboard_path(model_class).to_s }
    end

    def dashboard_exists?(model_class)
      registry = SuperAdmin::DashboardRegistry.instance
      return true if registry.dashboard_for(model_class)

      absolute_dashboard_path(model_class).exist?
    end

    def absolute_dashboard_path(model_class)
      Rails.root.join(relative_dashboard_path(model_class))
    end

    def relative_dashboard_path(model_class)
      Pathname.new(File.join("app", "dashboards", "super_admin", *namespace_segments(model_class), "#{model_basename(model_class)}_dashboard.rb"))
    end

    def namespace_segments(model_class)
      relative_namespace_constants(model_class).map { |segment| segment.underscore }
    end

    def namespace_constants(model_class)
      namespace = model_class.name.deconstantize
      return [] if namespace.empty?

      namespace.split("::")
    end

    def relative_namespace_constants(model_class)
      segments = namespace_constants(model_class)
      segments.shift if segments.first == root_namespace
      segments
    end

    def model_basename(model_class)
      model_class.name.demodulize.underscore
    end

    def dashboard_template(model_class)
      collection_attrs = default_collection_attributes(model_class)
      show_attrs = default_show_attributes(model_class)
      form_attrs = default_form_attributes(model_class)

      lines = []
      lines << "# frozen_string_literal: true"
      lines << ""

      indent = 0
      append(lines, indent, "module SuperAdmin")
      indent += 1

      relative_namespace_constants(model_class).each do |namespace|
        append(lines, indent, "module #{namespace}")
        indent += 1
      end

      append(lines, indent, "class #{model_class.name.demodulize}Dashboard < SuperAdmin::BaseDashboard")
      indent += 1
      append(lines, indent, "resource #{model_class.name}")
      append_attribute_declaration(lines, indent, "collection_attributes", collection_attrs)
      append_attribute_declaration(lines, indent, "show_attributes", show_attrs)
      append_attribute_declaration(lines, indent, "form_attributes", form_attrs)
      indent -= 1
      append(lines, indent, "end")

      relative_namespace_constants(model_class).reverse_each do |_namespace|
        indent -= 1
        append(lines, indent, "end")
      end

      indent -= 1
      append(lines, indent, "end")

      lines.join("\n") + "\n"
    end

    def append(lines, indent, text)
      lines << ("  " * indent + text)
    end

    def append_attribute_declaration(lines, indent, macro, attributes)
      return if attributes.empty?

      append(lines, indent, "#{macro} #{format_attribute_list(attributes, indent)}")
    end

    def default_collection_attributes(model_class)
      SuperAdmin::ResourceConfiguration
        .displayable_attributes(model_class)
        .map { |attr| normalize_attribute_name(attr) }
    end

    def default_show_attributes(model_class)
      SuperAdmin::ResourceConfiguration
        .displayable_attributes(model_class)
        .map { |attr| normalize_attribute_name(attr) }
    end

    def default_form_attributes(model_class)
      SuperAdmin::ResourceConfiguration
        .editable_attributes(model_class)
        .map { |attr| normalize_attribute_name(attr) }
    end

    def normalize_attribute_name(attribute)
      attribute.is_a?(Symbol) ? attribute : attribute.to_s.to_sym
    end

    def format_attribute_list(attributes, indent)
      tokens = attributes.map { |attr| ":#{attr}" }
      single_line = tokens.join(", ")
      return single_line if single_line.length <= 80

      continuation_indent = "\n" + ("  " * indent) + "  "
      tokens.join(",#{continuation_indent}")
    end

    def root_namespace
      "SuperAdmin"
    end

    def engine_owned_model?(model)
      model.name.start_with?("#{root_namespace}::")
    end

    def print_summary(generated, skipped)
      stdout.puts
      stdout.puts "Dashboards generated: #{generated.count}"
      stdout.puts "  - #{generated.join("\n  - ")}" if generated.any?
      stdout.puts "Dashboards skipped: #{skipped.count}"
      stdout.puts "  - #{skipped.join("\n  - ")}" if skipped.any?

      if generated.empty?
        if skipped.any?
          stdout.puts "No dashboards created; all models already have dashboards."
        else
          stdout.puts "No dashboards created."
        end
      end
    end
  end
end
