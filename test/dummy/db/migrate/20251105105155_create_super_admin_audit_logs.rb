# frozen_string_literal: true

class CreateSuperAdminAuditLogs < ActiveRecord::Migration[7.1]
  def change
    return if table_exists?(:super_admin_audit_logs)

    create_table :super_admin_audit_logs do |t|
      t.references :user, null: true, foreign_key: false, index: true
      t.string :user_email
      t.string :resource_type, null: false
      t.string :resource_id
      t.string :action, null: false
      t.json :changes_snapshot, null: false, default: {}
      t.json :context, null: false, default: {}
      t.datetime :performed_at, null: false

      t.timestamps
    end

    add_index :super_admin_audit_logs, :performed_at
    add_index :super_admin_audit_logs, [ :resource_type, :resource_id ]
    add_index :super_admin_audit_logs, :action
  end
end
