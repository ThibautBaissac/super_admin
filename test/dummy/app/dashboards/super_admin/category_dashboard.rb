# frozen_string_literal: true

module SuperAdmin
  class CategoryDashboard < SuperAdmin::BaseDashboard
    resource Category
    collection_attributes :id, :name, :description, :position, :visible, :slug, :posts_count
    show_attributes :id, :name, :description, :position, :visible, :slug, :posts_count
    form_attributes :name, :description, :position, :visible, :slug, :posts_count
  end
end
