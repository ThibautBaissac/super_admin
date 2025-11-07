# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user, counter_cache: :comments_count

  validates :content, presence: true, length: { minimum: 3, maximum: 1000 }

  enum :status, {
    pending: "pending",
    approved: "approved",
    rejected: "rejected",
    spam: "spam"
  }, suffix: true

  scope :approved, -> { where(status: "approved") }
  scope :pending_review, -> { where(status: "pending") }
  scope :recent, -> { order(created_at: :desc) }

  def approve!
    update(status: "approved", approved_at: Time.current)
  end

  def reject!
    update(status: "rejected")
  end
end
