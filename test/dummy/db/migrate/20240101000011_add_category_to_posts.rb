# frozen_string_literal: true

class AddCategoryToPosts < ActiveRecord::Migration[7.1]
  def change
    add_reference :posts, :category, foreign_key: true
    add_column :posts, :view_count, :integer, default: 0, null: false
    add_column :posts, :featured, :boolean, default: false, null: false
    add_column :posts, :metadata, :json

    add_index :posts, :featured
  end
end
