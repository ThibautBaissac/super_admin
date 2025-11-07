# frozen_string_literal: true

class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
  belongs_to :category, optional: true, counter_cache: :posts_count
  has_many :comments, as: :commentable, dependent: :destroy
  has_and_belongs_to_many :tags

  accepts_nested_attributes_for :comments, allow_destroy: true, reject_if: :all_blank

  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :body, presence: true, length: { minimum: 10 }

  enum :status, { draft: "draft", published: "published", archived: "archived" }, suffix: true

  # Store JSON metadata
  store_accessor :metadata, :seo_title, :seo_description, :author_notes

  scope :published, -> { where(status: "published") }
  scope :recent, -> { order(published_at: :desc) }
  scope :featured, -> { where(featured: true) }
  scope :popular, -> { where("view_count > ?", 100).order(view_count: :desc) }
  scope :by_category, ->(category_id) { where(category_id: category_id) }

  def increment_view_count!
    increment!(:view_count)
  end
end
