# frozen_string_literal: true

class CreateSuperAdminCsvExports < ActiveRecord::Migration[7.1]
  def change
    return if table_exists?(:super_admin_csv_exports)

    create_table :super_admin_csv_exports do |t|
      t.references :user, null: false, foreign_key: false, index: true
      t.string :resource_name, null: false
      t.string :model_class_name, null: false
      t.string :status, null: false, default: "pending"
      t.json :filters, null: false, default: {}
      t.string :search
      t.string :sort
      t.string :direction
      t.json :selected_attributes, null: false, default: []
      t.integer :records_count
      t.string :error_message
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :expires_at
      t.string :token, null: false

      t.timestamps
    end

    add_index :super_admin_csv_exports, :token, unique: true
    add_index :super_admin_csv_exports, :status
    add_index :super_admin_csv_exports, :resource_name
    add_index :super_admin_csv_exports, :created_at
    add_index :super_admin_csv_exports, :expires_at
  end
end
