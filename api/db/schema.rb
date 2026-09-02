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

ActiveRecord::Schema[8.1].define(version: 2026_09_02_220751) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "devise_api_tokens", force: :cascade do |t|
    t.string "access_token", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in", null: false
    t.string "previous_refresh_token"
    t.string "refresh_token"
    t.bigint "resource_owner_id", null: false
    t.string "resource_owner_type", null: false
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_devise_api_tokens_on_access_token", unique: true
    t.index ["previous_refresh_token"], name: "index_devise_api_tokens_on_previous_refresh_token"
    t.index ["refresh_token"], name: "index_devise_api_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_type", "resource_owner_id"], name: "index_devise_api_tokens_on_resource_owner"
  end

  create_table "inventories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_inventories_on_user_id", unique: true
  end

  create_table "inventory_slots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "inventory_id", null: false
    t.bigint "item_id", null: false
    t.integer "qty", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_id", "item_id"], name: "index_inventory_slots_on_inventory_id_and_item_id", unique: true
    t.index ["inventory_id"], name: "index_inventory_slots_on_inventory_id"
    t.index ["item_id"], name: "index_inventory_slots_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "happiness_delta", default: 0, null: false
    t.integer "hunger_delta", default: 0, null: false
    t.integer "hygiene_delta", default: 0, null: false
    t.string "name", null: false
    t.integer "price_coins", null: false
    t.integer "tiredness_delta", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "pets", force: :cascade do |t|
    t.datetime "action_ends_at"
    t.string "active_action"
    t.datetime "birth_date", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.integer "happiness", default: 70, null: false
    t.integer "health", default: 75, null: false
    t.integer "hunger", default: 30, null: false
    t.integer "hygiene", default: 80, null: false
    t.boolean "is_alive", default: true, null: false
    t.datetime "last_interaction", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "name", limit: 32, null: false
    t.boolean "needs_bath", default: false, null: false
    t.boolean "needs_meal", default: false, null: false
    t.boolean "needs_walk", default: false, null: false
    t.string "species", limit: 16, null: false
    t.integer "tiredness", default: 20, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["is_alive"], name: "index_pets_on_is_alive"
    t.index ["user_id", "name"], name: "index_pets_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_pets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "coins", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "inventories", "users"
  add_foreign_key "inventory_slots", "inventories"
  add_foreign_key "inventory_slots", "items"
  add_foreign_key "pets", "users"
end
