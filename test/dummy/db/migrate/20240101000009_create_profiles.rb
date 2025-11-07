# frozen_string_literal: true

class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :avatar_url
      t.text :bio
      t.date :birth_date
      t.time :preferred_notification_time
      t.decimal :rating, precision: 3, scale: 2, default: 0.0
      t.json :preferences
      t.json :social_links
      t.string :phone_number
      t.string :website
      t.string :timezone, default: "UTC"
      t.integer :notification_frequency, default: 0
      t.boolean :email_notifications, default: true
      t.boolean :sms_notifications, default: false

      t.timestamps
    end
  end
end
