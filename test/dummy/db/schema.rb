# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_05_105156) do
  create_table "addresses", force: :cascade do |t|
    t.string "address_type", null: false
    t.string "city", null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.boolean "is_primary", default: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "postal_code", null: false
    t.string "state"
    t.string "street_line1", null: false
    t.string "street_line2"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index [ "address_type" ], name: "index_addresses_on_address_type"
    t.index [ "user_id", "is_primary" ], name: "index_addresses_on_user_id_and_is_primary"
    t.index [ "user_id" ], name: "index_addresses_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0
    t.integer "posts_count", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index [ "position" ], name: "index_categories_on_position"
    t.index [ "slug" ], name: "index_categories_on_slug", unique: true
    t.index [ "visible" ], name: "index_categories_on_visible"
  end

  create_table "comments", force: :cascade do |t|
    t.datetime "approved_at"
    t.integer "commentable_id", null: false
    t.string "commentable_type", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.integer "likes_count", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index [ "approved_at" ], name: "index_comments_on_approved_at"
    t.index [ "commentable_type", "commentable_id" ], name: "index_comments_on_commentable"
    t.index [ "status" ], name: "index_comments_on_status"
    t.index [ "user_id" ], name: "index_comments_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "body", null: false
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.boolean "featured", default: false, null: false
    t.json "metadata"
    t.datetime "published_at"
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "view_count", default: 0, null: false
    t.index [ "category_id" ], name: "index_posts_on_category_id"
    t.index [ "featured" ], name: "index_posts_on_featured"
    t.index [ "published_at" ], name: "index_posts_on_published_at"
    t.index [ "status" ], name: "index_posts_on_status"
    t.index [ "user_id" ], name: "index_posts_on_user_id"
  end

  create_table "posts_tags", id: false, force: :cascade do |t|
    t.integer "post_id", null: false
    t.integer "tag_id", null: false
    t.index [ "post_id", "tag_id" ], name: "index_posts_tags_on_post_id_and_tag_id", unique: true
    t.index [ "post_id" ], name: "index_posts_tags_on_post_id"
    t.index [ "tag_id" ], name: "index_posts_tags_on_tag_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "avatar_url"
    t.text "bio"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.boolean "email_notifications", default: true
    t.integer "notification_frequency", default: 0
    t.string "phone_number"
    t.json "preferences"
    t.time "preferred_notification_time"
    t.decimal "rating", precision: 3, scale: 2, default: "0.0"
    t.boolean "sms_notifications", default: false
    t.json "social_links"
    t.string "timezone", default: "UTC"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "website"
    t.index [ "user_id" ], name: "index_profiles_on_user_id", unique: true
  end

  create_table "super_admin_audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.json "changes_snapshot", default: {}, null: false
    t.json "context", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "performed_at", null: false
    t.string "resource_id"
    t.string "resource_type", null: false
    t.datetime "updated_at", null: false
    t.string "user_email"
    t.integer "user_id"
    t.index [ "action" ], name: "index_super_admin_audit_logs_on_action"
    t.index [ "performed_at" ], name: "index_super_admin_audit_logs_on_performed_at"
    t.index [ "resource_type", "resource_id" ], name: "index_super_admin_audit_logs_on_resource_type_and_resource_id"
    t.index [ "user_id" ], name: "index_super_admin_audit_logs_on_user_id"
  end

  create_table "super_admin_csv_exports", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "direction"
    t.string "error_message"
    t.datetime "expires_at"
    t.json "filters", default: {}, null: false
    t.string "model_class_name", null: false
    t.integer "records_count"
    t.string "resource_name", null: false
    t.string "search"
    t.json "selected_attributes", default: [], null: false
    t.string "sort"
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index [ "created_at" ], name: "index_super_admin_csv_exports_on_created_at"
    t.index [ "expires_at" ], name: "index_super_admin_csv_exports_on_expires_at"
    t.index [ "resource_name" ], name: "index_super_admin_csv_exports_on_resource_name"
    t.index [ "status" ], name: "index_super_admin_csv_exports_on_status"
    t.index [ "token" ], name: "index_super_admin_csv_exports_on_token", unique: true
    t.index [ "user_id" ], name: "index_super_admin_csv_exports_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0, null: false
    t.index [ "name" ], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.integer "posts_count", default: 0, null: false
    t.string "role", default: "user", null: false
    t.datetime "updated_at", null: false
    t.index [ "active" ], name: "index_users_on_active"
    t.index [ "email" ], name: "index_users_on_email", unique: true
    t.index [ "role" ], name: "index_users_on_role"
  end

  add_foreign_key "addresses", "users"
  add_foreign_key "comments", "users"
  add_foreign_key "posts", "categories"
  add_foreign_key "posts", "users"
  add_foreign_key "posts_tags", "posts"
  add_foreign_key "posts_tags", "tags"
  add_foreign_key "profiles", "users"
end
