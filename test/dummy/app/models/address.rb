# frozen_string_literal: true

class Address < ApplicationRecord
  belongs_to :user

  validates :street_line1, :city, :postal_code, :country, presence: true
  validates :address_type, presence: true, inclusion: { in: %w[home work billing shipping other] }
  validates :latitude, numericality: {
    greater_than_or_equal_to: -90,
    less_than_or_equal_to: 90,
    allow_nil: true
  }
  validates :longitude, numericality: {
    greater_than_or_equal_to: -180,
    less_than_or_equal_to: 180,
    allow_nil: true
  }

  enum :address_type, {
    home: "home",
    work: "work",
    billing: "billing",
    shipping: "shipping",
    other: "other"
  }, suffix: :address

  scope :primary, -> { where(is_primary: true) }
  scope :by_country, ->(country) { where(country: country) }

  def full_address
    [ street_line1, street_line2, city, state, postal_code, country ].compact.join(", ")
  end
end
