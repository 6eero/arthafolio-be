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

ActiveRecord::Schema[8.0].define(version: 20_250_706_204_700) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'pg_catalog.plpgsql'

  create_table 'holdings', force: :cascade do |t|
    t.integer 'category'
    t.string 'label'
    t.decimal 'quantity'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'prices', force: :cascade do |t|
    t.integer 'category'
    t.string 'label'
    t.decimal 'price'
    t.datetime 'retrieved_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.bigint 'holding_id', null: false
    t.index ['holding_id'], name: 'index_prices_on_holding_id'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'password_digest'
    t.string 'refresh_token'
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['refresh_token'], name: 'index_users_on_refresh_token', unique: true
  end

  add_foreign_key 'prices', 'holdings'
end
