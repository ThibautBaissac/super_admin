# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.references :commentable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.string :status, default: "pending", null: false
      t.integer :likes_count, default: 0, null: false
      t.datetime :approved_at
      t.string :ip_address

      t.timestamps
    end

    add_index :comments, :status
    add_index :comments, :approved_at
  end
end
