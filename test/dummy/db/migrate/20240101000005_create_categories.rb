# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 0
      t.boolean :visible, default: true, null: false
      t.string :slug, null: false
      t.integer :posts_count, default: 0, null: false

      t.timestamps
    end

    add_index :categories, :slug, unique: true
    add_index :categories, :position
    add_index :categories, :visible
  end
end
