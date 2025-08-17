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

ActiveRecord::Schema[8.0].define(version: 2025_07_25_055604) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "auto_buy_settings", force: :cascade do |t|
    t.bigint "price_alert_id", null: false
    t.bigint "user_id", null: false
    t.boolean "enabled", default: false
    t.integer "max_attempts", default: 3
    t.integer "attempts_count", default: 0
    t.string "payment_method_type"
    t.string "payment_method_id"
    t.text "billing_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["price_alert_id", "user_id"], name: "index_auto_buy_settings_on_price_alert_id_and_user_id", unique: true
    t.index ["price_alert_id"], name: "index_auto_buy_settings_on_price_alert_id"
    t.index ["user_id"], name: "index_auto_buy_settings_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "venue"
    t.string "category"
    t.string "subcategory"
    t.decimal "price"
    t.datetime "date"
    t.string "image_url"
    t.string "ticket_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "flight_alerts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "origin", null: false
    t.string "destination", null: false
    t.date "departure_date", null: false
    t.date "return_date"
    t.integer "passengers", default: 1
    t.string "cabin_class", default: "economy"
    t.decimal "price_min", precision: 10, scale: 2
    t.decimal "price_max", precision: 10, scale: 2
    t.decimal "target_price", precision: 10, scale: 2, null: false
    t.string "notification_method", default: "email"
    t.boolean "wedding_mode", default: false
    t.date "wedding_date"
    t.integer "guest_count", default: 1
    t.string "status", default: "active"
    t.jsonb "auto_buy_settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auto_buy_settings"], name: "index_flight_alerts_on_auto_buy_settings", using: :gin
    t.index ["departure_date"], name: "index_flight_alerts_on_departure_date"
    t.index ["origin", "destination"], name: "index_flight_alerts_on_origin_and_destination"
    t.index ["status"], name: "index_flight_alerts_on_status"
    t.index ["user_id"], name: "index_flight_alerts_on_user_id"
    t.index ["wedding_mode"], name: "index_flight_alerts_on_wedding_mode"
  end

  create_table "launch_subscribers", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_launch_subscribers_on_email", unique: true
  end

  create_table "price_alerts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "query"
    t.string "category", default: [], array: true
    t.string "venue_type", default: [], array: true
    t.string "artist"
    t.string "team"
    t.string "from"
    t.string "to"
    t.decimal "price_min", precision: 10, scale: 2
    t.decimal "price_max", precision: 10, scale: 2
    t.decimal "target_price", precision: 10, scale: 2, null: false
    t.string "notification_method", null: false
    t.string "status", default: "active", null: false
    t.datetime "triggered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "min_price", precision: 10, scale: 2
    t.decimal "max_price", precision: 10, scale: 2
    t.index ["status"], name: "index_price_alerts_on_status"
    t.index ["user_id", "status"], name: "index_price_alerts_on_user_id_and_status"
    t.index ["user_id"], name: "index_price_alerts_on_user_id"
  end

  create_table "subscribers", force: :cascade do |t|
    t.string "email", null: false
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_subscribers_on_email", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "auto_buy_settings", "price_alerts"
  add_foreign_key "auto_buy_settings", "users"
  add_foreign_key "flight_alerts", "users"
  add_foreign_key "price_alerts", "users"
end
