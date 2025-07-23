ActiveRecord::Schema[8.0].define(version: 2025_07_19_094334) do
  enable_extension "pg_catalog.plpgsql"

  create_table "holdings", force: :cascade do |t|
    t.integer "category"
    t.string "label"
    t.decimal "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_holdings_on_user_id"
  end

  create_table "playing_with_neon", id: :serial, force: :cascade do |t|
    t.text "name", null: false
    t.float "value", limit: 24
  end

  create_table "portfolio_snapshots", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "total_value"
    t.datetime "taken_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_portfolio_snapshots_on_user_id"
  end

  create_table "prices", force: :cascade do |t|
    t.integer "category"
    t.string "label"
    t.decimal "price"
    t.datetime "retrieved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["label"], name: "index_prices_on_label", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "refresh_token"
    t.string "username"
    t.boolean "hide_holdings", default: false
    t.string "preferred_currency", default: "EUR"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["refresh_token"], name: "index_users_on_refresh_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "holdings", "users"
  add_foreign_key "portfolio_snapshots", "users"
end
