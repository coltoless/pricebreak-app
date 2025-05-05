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

ActiveRecord::Schema[8.0].define(version: 2025_05_05_020402) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  add_foreign_key "price_alerts", "users"
end
