# frozen_string_literal: true

module SuperAdmin
  class PostDashboard < SuperAdmin::BaseDashboard
    resource Post
    collection_attributes :id,
      :title,
      :user_id,
      :body,
      :status,
      :published_at,
      :category_id,
      :view_count,
      :featured,
      :metadata
    show_attributes :id,
      :title,
      :user_id,
      :body,
      :status,
      :published_at,
      :category_id,
      :view_count,
      :featured,
      :metadata
    form_attributes :user_id,
      :title,
      :body,
      :status,
      :published_at,
      :category_id,
      :view_count,
      :featured,
      :metadata,
      :comments_attributes
  end
end
