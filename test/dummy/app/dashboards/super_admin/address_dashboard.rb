# frozen_string_literal: true

module SuperAdmin
  class AddressDashboard < SuperAdmin::BaseDashboard
    resource Address
    collection_attributes :id,
      :user_id,
      :address_type,
      :street_line1,
      :street_line2,
      :city,
      :state,
      :postal_code,
      :country,
      :is_primary,
      :latitude,
      :longitude
    show_attributes :id,
      :user_id,
      :address_type,
      :street_line1,
      :street_line2,
      :city,
      :state,
      :postal_code,
      :country,
      :is_primary,
      :latitude,
      :longitude
    form_attributes :user_id,
      :address_type,
      :street_line1,
      :street_line2,
      :city,
      :state,
      :postal_code,
      :country,
      :is_primary,
      :latitude,
      :longitude
  end
end
