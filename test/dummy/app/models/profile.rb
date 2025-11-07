# frozen_string_literal: true

class Profile < ApplicationRecord
  belongs_to :user

  validates :rating, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 5,
    allow_nil: true
  }
  validates :phone_number, format: {
    with: /\A[\+\d\s\-\(\)]+\z/,
    allow_blank: true
  }
  validates :website, format: {
    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
    allow_blank: true
  }

  enum :notification_frequency, {
    never: 0,
    daily: 1,
    weekly: 2,
    monthly: 3,
    real_time: 4
  }, prefix: :notify

  # Store JSON preferences
  store_accessor :preferences, :theme, :language, :items_per_page
  store_accessor :social_links, :twitter, :linkedin, :github

  scope :with_notifications, -> { where(email_notifications: true) }
  scope :birthday_today, -> { where("EXTRACT(MONTH FROM birth_date) = ? AND EXTRACT(DAY FROM birth_date) = ?", Date.current.month, Date.current.day) }
end
