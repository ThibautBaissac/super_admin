# frozen_string_literal: true

class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_one :profile, dependent: :destroy

  accepts_nested_attributes_for :posts, allow_destroy: true
  accepts_nested_attributes_for :addresses, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :profile, update_only: true

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  enum :role, { user: "user", admin: "admin", moderator: "moderator" }, suffix: true

  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_profile, -> { includes(:profile) }
  scope :admins, -> { where(role: "admin") }

  class << self
    # Override delete_all to ensure dependent associations are cleaned up.
    def delete_all(*args)
      scope = args.empty? ? all : where(*args)

      scope.find_each(&:destroy)
    end
  end
end
