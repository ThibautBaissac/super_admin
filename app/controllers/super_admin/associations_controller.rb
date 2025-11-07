# frozen_string_literal: true

module SuperAdmin
  # API controller for association search in forms.
  # Enables pagination and search in large collections.
  class AssociationsController < SuperAdmin::BaseController
    # GET /super_admin/associations/search
    # Parameters: model, q (query), page, selected_id
    def search
      model_class = SuperAdmin::ModelInspector.find_model(params[:model])

      unless model_class
        return render json: { error: "Model not found" }, status: :not_found
      end

      query = params[:q].to_s.strip
      page = [ params[:page].to_i, 1 ].max
      selected_id = params[:selected_id].presence
      per_page = SuperAdmin.association_pagination_limit

      scope = build_search_scope(model_class, query)

      total_count = scope.count
      records = scope.offset((page - 1) * per_page).limit(per_page)

      # Include currently selected record if not in results
      selected_record = nil
      if selected_id.present?
        selected_record = model_class.find_by(id: selected_id)
        records = [ selected_record ] + records.to_a if selected_record && page == 1
        records.uniq!(&:id) if selected_record
      end

      render json: {
        results: records.map { |r| { id: r.id, text: sanitize_output(display_label_for(r)) } },
        pagination: {
          more: (page * per_page) < total_count,
          page: page,
          per_page: per_page,
          total: total_count
        }
      }
    rescue StandardError => e
      Rails.logger.error("SuperAdmin::AssociationsController - Search error: #{e.message}")
      render json: { error: "Search failed" }, status: :internal_server_error
    end

    private

    def display_label_for(record)
      return record.to_s unless record.respond_to?(:attributes)

      name = record.respond_to?(:name) ? record.name.presence : nil
      email = record.respond_to?(:email) ? record.email.presence : nil
      title = record.respond_to?(:title) ? record.title.presence : nil
      label = record.respond_to?(:label) ? record.label.presence : nil

      if name && email
        "#{name} (#{email})"
      elsif name
        name
      elsif title && email
        "#{title} (#{email})"
      elsif title
        title
      elsif email
        email
      elsif label
        label
      else
        record.to_s
      end
    end

    def build_search_scope(model_class, query)
      scope = model_class.all

      return scope if query.blank?

      searchable_columns = detect_searchable_columns(model_class)

      return scope if searchable_columns.empty?

      # Build secure Arel conditions instead of string interpolation
      arel_table = model_class.arel_table
      sanitized_query = sanitize_sql_like(query)
      pattern = "%#{sanitized_query}%"

      # Use ILIKE for PostgreSQL (case-insensitive), LIKE with LOWER() for SQLite
      use_ilike = ActiveRecord::Base.connection.adapter_name.downcase.include?("postgres")

      arel_conditions = searchable_columns.map do |column_name|
        # Ensure column exists in the table to prevent injection
        next unless model_class.column_names.include?(column_name)

        column = arel_table[column_name.to_sym]

        if use_ilike
          column.matches(pattern, nil, true) # Third argument = case_insensitive for PostgreSQL
        else
          # For SQLite and other databases, use LOWER() for case-insensitive search
          Arel::Nodes::NamedFunction.new("LOWER", [ column ])
            .matches(Arel::Nodes.build_quoted(pattern.downcase))
        end
      end.compact

      return scope if arel_conditions.empty?

      # Combine conditions with OR
      combined_condition = arel_conditions.reduce { |memo, condition| memo.or(condition) }
      scope.where(combined_condition)
    end

    def detect_searchable_columns(model_class)
      string_columns = model_class.columns
                                  .select { |col| %i[string text].include?(col.type) }
                                  .map(&:name)

      priority_columns = %w[name title label email username]
      searchable = string_columns & priority_columns

      searchable = string_columns.first(3) if searchable.empty?

      searchable
    end

    def sanitize_sql_like(string)
      string.gsub(/[%_]/) { |match| "\\#{match}" }
    end

    # Sanitize output to prevent XSS attacks
    def sanitize_output(string)
      ERB::Util.html_escape(string.to_s)
    end
  end
end
