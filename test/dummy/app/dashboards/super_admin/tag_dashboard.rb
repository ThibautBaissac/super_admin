# frozen_string_literal: true

module SuperAdmin
  class TagDashboard < SuperAdmin::BaseDashboard
    resource Tag
    collection_attributes :id, :name, :color, :usage_count
    show_attributes :id, :name, :color, :usage_count
    form_attributes :name, :color, :usage_count
  end
end
