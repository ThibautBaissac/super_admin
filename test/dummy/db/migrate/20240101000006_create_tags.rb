# frozen_string_literal: true

class CreateTags < ActiveRecord::Migration[7.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.string :color
      t.integer :usage_count, default: 0, null: false

      t.timestamps
    end

    add_index :tags, :name, unique: true
  end
end
