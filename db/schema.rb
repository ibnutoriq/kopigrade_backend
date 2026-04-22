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

ActiveRecord::Schema[8.1].define(version: 2026_04_22_110839) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_clients", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_clients_on_token_digest", unique: true
  end

  create_table "market_prices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "price", null: false
    t.date "price_date", null: false
    t.string "source_url"
    t.datetime "updated_at", null: false
    t.string "variety", null: false
    t.index ["variety", "price_date"], name: "index_market_prices_on_variety_and_price_date", unique: true
  end

  create_table "scan_results", force: :cascade do |t|
    t.text "advice"
    t.bigint "api_client_id"
    t.integer "black_defects", default: 0, null: false
    t.integer "broken_defects", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "device_id"
    t.text "error_message"
    t.boolean "export_eligible"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "public_token", null: false
    t.datetime "scanned_at"
    t.decimal "sni_defect_value", precision: 6, scale: 2
    t.string "sni_grade"
    t.string "status", default: "pending"
    t.string "sub_district"
    t.integer "total_beans", null: false
    t.datetime "updated_at", null: false
    t.string "variety", default: "robusta"
    t.index ["api_client_id"], name: "index_scan_results_on_api_client_id"
    t.index ["created_at"], name: "index_scan_results_on_created_at"
    t.index ["public_token"], name: "index_scan_results_on_public_token", unique: true
    t.index ["sni_grade"], name: "index_scan_results_on_sni_grade"
    t.index ["status"], name: "index_scan_results_on_status"
    t.index ["sub_district"], name: "index_scan_results_on_sub_district"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "scan_results", "api_clients"
  add_foreign_key "sessions", "users"
end
