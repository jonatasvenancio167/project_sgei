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

ActiveRecord::Schema[8.0].define(version: 2026_05_07_003412) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "churches", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_churches_on_slug", unique: true
  end

  create_table "departaments", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id"], name: "index_departaments_on_church_id"
    t.index ["name"], name: "index_departaments_on_name"
  end

  create_table "event_attendees", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "user_id", null: false
    t.string "guest_name"
    t.string "guest_phone"
    t.string "guest_email"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "user_id"], name: "index_event_attendees_on_event_id_and_user_id", unique: true
    t.index ["event_id"], name: "index_event_attendees_on_event_id"
    t.index ["user_id"], name: "index_event_attendees_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.bigint "departament_id", null: false
    t.string "title", null: false
    t.string "slug"
    t.string "description"
    t.string "thumbnail"
    t.string "location"
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.bigint "created_by_id"
    t.integer "visibility", default: 0
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id"], name: "index_events_on_church_id"
    t.index ["created_by_id"], name: "index_events_on_created_by_id"
    t.index ["deleted_at"], name: "index_events_on_deleted_at"
    t.index ["departament_id"], name: "index_events_on_departament_id"
    t.index ["slug"], name: "index_events_on_slug"
    t.index ["start_date", "end_date"], name: "index_events_on_start_date_and_end_date"
  end

  create_table "form_answers", force: :cascade do |t|
    t.bigint "form_id", null: false
    t.bigint "form_field_id"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["form_field_id"], name: "index_form_answers_on_form_field_id"
    t.index ["form_id"], name: "index_form_answers_on_form_id"
    t.index ["value"], name: "index_form_answers_on_value"
  end

  create_table "form_fields", force: :cascade do |t|
    t.bigint "form_id", null: false
    t.string "label", null: false
    t.string "label_type", null: false
    t.boolean "required", default: false
    t.jsonb "options", default: {}
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["form_id"], name: "index_form_fields_on_form_id"
    t.index ["label_type"], name: "index_form_fields_on_label_type"
    t.index ["position"], name: "index_form_fields_on_position"
  end

  create_table "form_responses", force: :cascade do |t|
    t.bigint "form_id", null: false
    t.bigint "user_id", null: false
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["form_id"], name: "index_form_responses_on_form_id"
    t.index ["user_id"], name: "index_form_responses_on_user_id"
  end

  create_table "forms", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.bigint "event_id"
    t.string "title"
    t.string "description"
    t.boolean "active", default: true
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_forms_on_active"
    t.index ["church_id"], name: "index_forms_on_church_id"
    t.index ["deleted_at"], name: "index_forms_on_deleted_at"
    t.index ["event_id"], name: "index_forms_on_event_id"
  end

  create_table "integrations", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.string "provider", null: false
    t.string "api_key"
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id"], name: "index_integrations_on_church_id"
  end

  create_table "memberchips", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "departament_id", null: false
    t.integer "role", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["departament_id"], name: "index_memberchips_on_departament_id"
    t.index ["user_id", "departament_id"], name: "index_memberchips_on_user_id_and_departament_id", unique: true
    t.index ["user_id"], name: "index_memberchips_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.string "title"
    t.text "message"
    t.integer "notification_type", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id"], name: "index_notifications_on_church_id"
  end

  create_table "user_notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "notification_id", null: false
    t.boolean "read", default: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_id"], name: "index_user_notifications_on_notification_id"
    t.index ["read"], name: "index_user_notifications_on_read"
    t.index ["user_id"], name: "index_user_notifications_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone"
    t.integer "role", default: 2
    t.boolean "active", default: true
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id"], name: "index_users_on_church_id"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email"
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "departaments", "churches"
  add_foreign_key "event_attendees", "events"
  add_foreign_key "event_attendees", "users"
  add_foreign_key "events", "churches"
  add_foreign_key "events", "departaments"
  add_foreign_key "events", "users", column: "created_by_id"
  add_foreign_key "form_answers", "form_fields"
  add_foreign_key "form_answers", "forms"
  add_foreign_key "form_fields", "forms"
  add_foreign_key "form_responses", "forms"
  add_foreign_key "form_responses", "users"
  add_foreign_key "forms", "churches"
  add_foreign_key "forms", "events"
  add_foreign_key "integrations", "churches"
  add_foreign_key "memberchips", "departaments"
  add_foreign_key "memberchips", "users"
  add_foreign_key "notifications", "churches"
  add_foreign_key "user_notifications", "notifications"
  add_foreign_key "user_notifications", "users"
  add_foreign_key "users", "churches"
end
