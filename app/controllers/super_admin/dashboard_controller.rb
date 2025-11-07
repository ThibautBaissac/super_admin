# frozen_string_literal: true

module SuperAdmin
  # SuperAdmin dashboard controller displaying all administrable models.
  class DashboardController < SuperAdmin::BaseController
    def index
      @models_info = available_models.map do |model_class|
        begin
          count = model_class.count
        rescue ActiveRecord::StatementInvalid, StandardError => e
          Rails.logger.warn("Cannot count #{model_class.name}: #{e.message}")
          count = 0
        end

        {
          class: model_class,
          name: model_class.name,
          human_name: model_display_name(model_class),
          count: count,
          table_name: model_class.table_name,
          path: model_path(model_class)
        }
      rescue StandardError => e
        Rails.logger.error("Error inspecting model #{model_class.name}: #{e.message}")
        nil
      end.compact
    end
  end
end
