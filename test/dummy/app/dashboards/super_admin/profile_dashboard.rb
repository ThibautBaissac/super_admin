# frozen_string_literal: true

module SuperAdmin
  class ProfileDashboard < SuperAdmin::BaseDashboard
    resource Profile
    collection_attributes :id,
      :user_id,
      :avatar_url,
      :bio,
      :birth_date,
      :preferred_notification_time,
      :rating,
      :preferences,
      :social_links,
      :phone_number,
      :website,
      :timezone,
      :notification_frequency,
      :email_notifications,
      :sms_notifications
    show_attributes :id,
      :user_id,
      :avatar_url,
      :bio,
      :birth_date,
      :preferred_notification_time,
      :rating,
      :preferences,
      :social_links,
      :phone_number,
      :website,
      :timezone,
      :notification_frequency,
      :email_notifications,
      :sms_notifications
    form_attributes :user_id,
      :avatar_url,
      :bio,
      :birth_date,
      :preferred_notification_time,
      :rating,
      :preferences,
      :social_links,
      :phone_number,
      :website,
      :timezone,
      :notification_frequency,
      :email_notifications,
      :sms_notifications
  end
end
