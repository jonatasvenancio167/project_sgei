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

ActiveRecord::Schema[8.0].define(version: 2026_08_05_191845) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "street"
    t.string "number"
    t.string "complement"
    t.string "neighborhood"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.bigint "user_id"
    t.string "module_key", null: false
    t.string "action", null: false
    t.string "detail"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id", "created_at"], name: "index_audit_logs_on_church_id_and_created_at"
    t.index ["church_id"], name: "index_audit_logs_on_church_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "churches", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.string "cnpj"
    t.string "website"
    t.date "founded_at"
    t.string "timezone", default: "America/Fortaleza", null: false
    t.string "primary_color", default: "#4f6e5d", null: false
    t.integer "church_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "responsible_name"
    t.bigint "address_id"
    t.bigint "parent_church_id"
    t.index ["address_id"], name: "index_churches_on_address_id"
    t.index ["parent_church_id"], name: "index_churches_on_parent_church_id"
    t.index ["slug"], name: "index_churches_on_slug", unique: true
  end

  create_table "departaments", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color", default: "bg-blue-500 text-white"
    t.string "icon", default: "users"
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
    t.bigint "departament_id"
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
    t.integer "event_attendees_count"
    t.integer "status", default: 0, null: false
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.string "rejection_reason"
    t.datetime "cancelled_at"
    t.bigint "cancelled_by_id"
    t.string "cancel_reason"
    t.time "start_time"
    t.time "end_time"
    t.boolean "registration_enabled", default: false, null: false
    t.integer "registration_limit", default: 0
    t.index ["approved_by_id"], name: "index_events_on_approved_by_id"
    t.index ["church_id", "status"], name: "index_events_on_church_and_status"
    t.index ["church_id"], name: "index_events_on_church_id"
    t.index ["created_by_id"], name: "index_events_on_created_by_id"
    t.index ["deleted_at"], name: "index_events_on_deleted_at"
    t.index ["departament_id"], name: "index_events_on_departament_id"
    t.index ["slug"], name: "index_events_on_slug"
    t.index ["start_date", "end_date"], name: "index_events_on_start_date_and_end_date"
    t.index ["status"], name: "index_events_on_status"
  end

  create_table "form_answers", force: :cascade do |t|
    t.bigint "form_id", null: false
    t.bigint "form_field_id"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "form_response_id"
    t.index ["form_field_id"], name: "index_form_answers_on_form_field_id"
    t.index ["form_id"], name: "index_form_answers_on_form_id"
    t.index ["form_response_id"], name: "index_form_answers_on_form_response_id"
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
    t.bigint "user_id"
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token"
    t.string "guest_name"
    t.string "guest_email"
    t.string "guest_phone"
    t.index ["form_id"], name: "index_form_responses_on_form_id"
    t.index ["token"], name: "index_form_responses_on_token", unique: true
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
    t.bigint "departament_id"
    t.integer "limit"
    t.string "slug"
    t.string "banner_url"
    t.index ["active"], name: "index_forms_on_active"
    t.index ["church_id"], name: "index_forms_on_church_id"
    t.index ["deleted_at"], name: "index_forms_on_deleted_at"
    t.index ["departament_id"], name: "index_forms_on_departament_id"
    t.index ["event_id"], name: "index_forms_on_event_id"
    t.index ["slug"], name: "index_forms_on_slug", unique: true
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

  create_table "notification_settings", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.string "event_key", null: false
    t.boolean "active", default: true, null: false
    t.integer "channel", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id", "event_key"], name: "index_notification_settings_on_church_id_and_event_key", unique: true
    t.index ["church_id"], name: "index_notification_settings_on_church_id"
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

  create_table "role_permissions", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.integer "role", null: false
    t.string "module_key", null: false
    t.boolean "allowed", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id", "role", "module_key"], name: "index_role_permissions_on_church_id_and_role_and_module_key", unique: true
    t.index ["church_id"], name: "index_role_permissions_on_church_id"
  end

  create_table "schedule_assignments", force: :cascade do |t|
    t.bigint "schedule_entry_id", null: false
    t.bigint "user_id", null: false
    t.bigint "schedule_column_id", null: false
    t.datetime "notified_at"
    t.datetime "reminder_7d_sent_at"
    t.datetime "reminder_3d_sent_at"
    t.datetime "reminder_1d_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["schedule_column_id"], name: "index_schedule_assignments_on_schedule_column_id"
    t.index ["schedule_entry_id", "user_id", "schedule_column_id"], name: "index_schedule_assignments_uniqueness", unique: true
    t.index ["schedule_entry_id"], name: "index_schedule_assignments_on_schedule_entry_id"
    t.index ["user_id"], name: "index_schedule_assignments_on_user_id"
  end

  create_table "schedule_columns", force: :cascade do |t|
    t.bigint "schedule_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "column_type", default: "text", null: false
    t.index ["schedule_id", "position"], name: "index_schedule_columns_on_schedule_id_and_position"
    t.index ["schedule_id"], name: "index_schedule_columns_on_schedule_id"
  end

  create_table "schedule_entries", force: :cascade do |t|
    t.bigint "schedule_id", null: false
    t.string "month", null: false
    t.integer "position", default: 0, null: false
    t.jsonb "cell_values", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date"
    t.index ["date"], name: "index_schedule_entries_on_date"
    t.index ["schedule_id", "month"], name: "index_schedule_entries_on_schedule_id_and_month"
    t.index ["schedule_id"], name: "index_schedule_entries_on_schedule_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.bigint "departament_id", null: false
    t.string "name", null: false
    t.string "color", default: "bg-blue-500 text-white", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id"], name: "index_schedules_on_church_id"
    t.index ["departament_id"], name: "index_schedules_on_departament_id"
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
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "status", default: 0
    t.bigint "address_id"
    t.date "birth_date"
    t.index "EXTRACT(month FROM birth_date), EXTRACT(day FROM birth_date)", name: "index_users_on_birth_date_month_day"
    t.index ["address_id"], name: "index_users_on_address_id"
    t.index ["church_id"], name: "index_users_on_church_id"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "welcome_records", force: :cascade do |t|
    t.bigint "church_id", null: false
    t.bigint "registered_by_id"
    t.string "name", null: false
    t.integer "visitor_type", default: 0, null: false
    t.string "congregation"
    t.string "city"
    t.string "phone"
    t.string "service", null: false
    t.text "notes"
    t.boolean "became_member", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["church_id", "created_at"], name: "index_welcome_records_on_church_id_and_created_at"
    t.index ["church_id"], name: "index_welcome_records_on_church_id"
    t.index ["registered_by_id"], name: "index_welcome_records_on_registered_by_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_logs", "churches"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "churches", "addresses"
  add_foreign_key "churches", "churches", column: "parent_church_id"
  add_foreign_key "departaments", "churches"
  add_foreign_key "event_attendees", "events"
  add_foreign_key "event_attendees", "users"
  add_foreign_key "events", "churches"
  add_foreign_key "events", "departaments"
  add_foreign_key "events", "users", column: "approved_by_id"
  add_foreign_key "events", "users", column: "cancelled_by_id"
  add_foreign_key "events", "users", column: "created_by_id"
  add_foreign_key "form_answers", "form_fields"
  add_foreign_key "form_answers", "form_responses"
  add_foreign_key "form_answers", "forms"
  add_foreign_key "form_fields", "forms"
  add_foreign_key "form_responses", "forms"
  add_foreign_key "form_responses", "users"
  add_foreign_key "forms", "churches"
  add_foreign_key "forms", "departaments"
  add_foreign_key "forms", "events"
  add_foreign_key "integrations", "churches"
  add_foreign_key "memberchips", "departaments"
  add_foreign_key "memberchips", "users"
  add_foreign_key "notification_settings", "churches"
  add_foreign_key "notifications", "churches"
  add_foreign_key "role_permissions", "churches"
  add_foreign_key "schedule_assignments", "schedule_columns"
  add_foreign_key "schedule_assignments", "schedule_entries"
  add_foreign_key "schedule_assignments", "users"
  add_foreign_key "schedule_columns", "schedules"
  add_foreign_key "schedule_entries", "schedules"
  add_foreign_key "schedules", "churches"
  add_foreign_key "schedules", "departaments"
  add_foreign_key "user_notifications", "notifications"
  add_foreign_key "user_notifications", "users"
  add_foreign_key "users", "addresses"
  add_foreign_key "users", "churches"
  add_foreign_key "welcome_records", "churches"
  add_foreign_key "welcome_records", "users", column: "registered_by_id"
end
