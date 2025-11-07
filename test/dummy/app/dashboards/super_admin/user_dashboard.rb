# frozen_string_literal: true

module SuperAdmin
  class UserDashboard < SuperAdmin::BaseDashboard
    resource User
    collection_attributes :id, :email, :name, :role, :active, :posts_count, :comments_count
    show_attributes :id, :email, :name, :role, :active, :posts_count, :comments_count
    form_attributes :email,
      :name,
      :role,
      :active,
      :posts_count,
      :comments_count,
      :posts_attributes,
      :addresses_attributes,
      :profile_attributes
  end
end
