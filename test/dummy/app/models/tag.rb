# frozen_string_literal: true

class Tag < ApplicationRecord
  has_and_belongs_to_many :posts

  validates :name, presence: true, uniqueness: true
  validates :color, format: { with: /\A#[0-9A-F]{6}\z/i, allow_blank: true }

  scope :popular, -> { where("usage_count > ?", 5).order(usage_count: :desc) }
  scope :alphabetical, -> { order(name: :asc) }
end
