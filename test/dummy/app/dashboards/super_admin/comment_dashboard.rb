# frozen_string_literal: true

module SuperAdmin
  class CommentDashboard < SuperAdmin::BaseDashboard
    resource Comment
    collection_attributes :id,
      :commentable_type,
      :commentable_id,
      :user_id,
      :content,
      :status,
      :likes_count,
      :approved_at,
      :ip_address
    show_attributes :id,
      :commentable_type,
      :commentable_id,
      :user_id,
      :content,
      :status,
      :likes_count,
      :approved_at,
      :ip_address
    form_attributes :commentable_type,
      :commentable_id,
      :user_id,
      :content,
      :status,
      :likes_count,
      :approved_at,
      :ip_address
  end
end
