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

ActiveRecord::Schema[8.1].define(version: 2025_11_15_233457) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "auto_buy_settings", force: :cascade do |t|
    t.integer "attempts_count", default: 0
    t.text "billing_address"
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false
    t.integer "max_attempts", default: 3
    t.string "payment_method_id"
    t.string "payment_method_type"
    t.bigint "price_alert_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["price_alert_id", "user_id"], name: "index_auto_buy_settings_on_price_alert_id_and_user_id", unique: true
    t.index ["price_alert_id"], name: "index_auto_buy_settings_on_price_alert_id"
    t.index ["user_id"], name: "index_auto_buy_settings_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "date"
    t.text "description"
    t.string "image_url"
    t.string "name"
    t.decimal "price"
    t.string "subcategory"
    t.string "ticket_url"
    t.datetime "updated_at", null: false
    t.string "venue"
  end

  create_table "flight_alerts", force: :cascade do |t|
    t.decimal "alert_quality_score", precision: 3, scale: 2, default: "1.0"
    t.string "alert_status"
    t.jsonb "alert_triggers", default: {}
    t.jsonb "auto_buy_settings", default: {}
    t.jsonb "booking_actions", default: {}
    t.string "cabin_class", default: "economy"
    t.datetime "created_at", null: false
    t.decimal "current_price", precision: 10, scale: 2
    t.date "departure_date", null: false
    t.string "destination", null: false
    t.bigint "flight_filter_id"
    t.integer "guest_count", default: 1
    t.datetime "last_checked"
    t.datetime "next_check_scheduled"
    t.jsonb "notification_history", default: {}
    t.string "notification_method", default: "email"
    t.string "origin", null: false
    t.integer "passengers", default: 1
    t.decimal "price_drop_amount"
    t.decimal "price_drop_percentage", precision: 5, scale: 2
    t.decimal "price_max", precision: 10, scale: 2
    t.decimal "price_min", precision: 10, scale: 2
    t.date "return_date"
    t.string "status", default: "active"
    t.decimal "target_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.date "wedding_date"
    t.boolean "wedding_mode", default: false
    t.index ["alert_triggers"], name: "index_flight_alerts_on_alert_triggers", using: :gin
    t.index ["auto_buy_settings"], name: "index_flight_alerts_on_auto_buy_settings", using: :gin
    t.index ["booking_actions"], name: "index_flight_alerts_on_booking_actions", using: :gin
    t.index ["current_price"], name: "index_flight_alerts_on_current_price"
    t.index ["departure_date"], name: "index_flight_alerts_on_departure_date"
    t.index ["flight_filter_id"], name: "index_flight_alerts_on_flight_filter_id"
    t.index ["next_check_scheduled"], name: "index_flight_alerts_on_next_check_scheduled"
    t.index ["notification_history"], name: "index_flight_alerts_on_notification_history", using: :gin
    t.index ["origin", "destination"], name: "index_flight_alerts_on_origin_and_destination"
    t.index ["status"], name: "index_flight_alerts_on_status"
    t.index ["user_id"], name: "index_flight_alerts_on_user_id"
    t.index ["wedding_mode"], name: "index_flight_alerts_on_wedding_mode"
  end

  create_table "flight_filters", force: :cascade do |t|
    t.jsonb "advanced_preferences", default: {}, null: false
    t.jsonb "alert_settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.integer "date_flexibility", default: 3
    t.text "departure_dates", null: false
    t.text "description"
    t.text "destination_airports", null: false
    t.boolean "flexible_dates", default: false
    t.boolean "is_active", default: true
    t.string "name", null: false
    t.text "origin_airports", null: false
    t.jsonb "passenger_details", default: {}, null: false
    t.jsonb "price_parameters", default: {}, null: false
    t.text "return_dates"
    t.string "trip_type", default: "round-trip", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["advanced_preferences"], name: "index_flight_filters_on_advanced_preferences", using: :gin
    t.index ["alert_settings"], name: "index_flight_filters_on_alert_settings", using: :gin
    t.index ["is_active"], name: "index_flight_filters_on_is_active"
    t.index ["passenger_details"], name: "index_flight_filters_on_passenger_details", using: :gin
    t.index ["price_parameters"], name: "index_flight_filters_on_price_parameters", using: :gin
    t.index ["trip_type"], name: "index_flight_filters_on_trip_type"
    t.index ["user_id"], name: "index_flight_filters_on_user_id"
  end

  create_table "flight_price_histories", force: :cascade do |t|
    t.string "booking_class", null: false
    t.datetime "created_at", null: false
    t.decimal "data_quality_score", precision: 3, scale: 2, default: "1.0"
    t.date "date", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "price_validation_status", default: "valid"
    t.string "provider", null: false
    t.string "route", null: false
    t.datetime "timestamp", null: false
    t.datetime "updated_at", null: false
    t.index ["data_quality_score"], name: "index_flight_price_histories_on_data_quality_score"
    t.index ["date"], name: "index_flight_price_histories_on_date"
    t.index ["price"], name: "index_flight_price_histories_on_price"
    t.index ["price_validation_status"], name: "index_flight_price_histories_on_price_validation_status"
    t.index ["provider"], name: "index_flight_price_histories_on_provider"
    t.index ["route", "date", "provider"], name: "index_flight_price_histories_on_route_and_date_and_provider", unique: true
    t.index ["route"], name: "index_flight_price_histories_on_route"
    t.index ["timestamp"], name: "index_flight_price_histories_on_timestamp"
  end

  create_table "flight_provider_data", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "data_timestamp", null: false
    t.string "duplicate_group_id"
    t.string "flight_identifier", null: false
    t.jsonb "pricing", default: {}, null: false
    t.string "provider", null: false
    t.string "route", null: false
    t.jsonb "schedule", default: {}, null: false
    t.datetime "updated_at", null: false
    t.string "validation_status", default: "pending"
    t.index ["data_timestamp"], name: "index_flight_provider_data_on_data_timestamp"
    t.index ["duplicate_group_id"], name: "index_flight_provider_data_on_duplicate_group_id"
    t.index ["flight_identifier", "provider"], name: "index_flight_provider_data_on_flight_identifier_and_provider", unique: true
    t.index ["flight_identifier"], name: "index_flight_provider_data_on_flight_identifier"
    t.index ["pricing"], name: "index_flight_provider_data_on_pricing", using: :gin
    t.index ["provider"], name: "index_flight_provider_data_on_provider"
    t.index ["route"], name: "index_flight_provider_data_on_route"
    t.index ["schedule"], name: "index_flight_provider_data_on_schedule", using: :gin
    t.index ["validation_status"], name: "index_flight_provider_data_on_validation_status"
  end

  create_table "launch_subscribers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_launch_subscribers_on_email", unique: true
  end

  create_table "price_alerts", force: :cascade do |t|
    t.string "artist"
    t.string "category", default: [], array: true
    t.datetime "created_at", null: false
    t.string "from"
    t.decimal "max_price", precision: 10, scale: 2
    t.decimal "min_price", precision: 10, scale: 2
    t.string "notification_method", null: false
    t.decimal "price_max", precision: 10, scale: 2
    t.decimal "price_min", precision: 10, scale: 2
    t.string "query"
    t.string "status", default: "active", null: false
    t.decimal "target_price", precision: 10, scale: 2, null: false
    t.string "team"
    t.string "to"
    t.datetime "triggered_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "venue_type", default: [], array: true
    t.index ["status"], name: "index_price_alerts_on_status"
    t.index ["user_id", "status"], name: "index_price_alerts_on_user_id_and_status"
    t.index ["user_id"], name: "index_price_alerts_on_user_id"
  end

  create_table "subscribers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_subscribers_on_email", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "USD"
    t.string "email", default: "", null: false
    t.boolean "email_subscription", default: false
    t.string "encrypted_password", default: "", null: false
    t.string "firebase_uid"
    t.string "home_city"
    t.string "language", default: "en"
    t.string "name"
    t.jsonb "preferred_airports", default: []
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "timezone", default: "UTC"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["firebase_uid"], name: "index_users_on_firebase_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "auto_buy_settings", "price_alerts"
  add_foreign_key "auto_buy_settings", "users"
  add_foreign_key "flight_alerts", "flight_filters"
  add_foreign_key "flight_alerts", "users"
  add_foreign_key "flight_filters", "users"
  add_foreign_key "price_alerts", "users"
end
