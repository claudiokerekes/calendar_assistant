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

ActiveRecord::Schema[7.2].define(version: 2025_10_28_215723) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "calendar_configs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "day_of_week"
    t.time "start_time"
    t.time "end_time"
    t.boolean "is_active"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_calendar_configs_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "whatsapp_client", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "whatsapp_client"], name: "index_conversations_on_user_id_and_whatsapp_client", unique: true
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.text "message_content", null: false
    t.integer "user_type", null: false
    t.integer "prompt_tokens"
    t.integer "completion_tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.string "google_id", null: false
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "expires_at"
    t.string "provider", default: "google"
    t.string "plan", default: "basic"
    t.integer "whatsapp_numbers_limit", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_id"], name: "index_users_on_google_id", unique: true
  end

  create_table "whatsapp_numbers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "phone_number", null: false
    t.string "webhook_url"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone_number"], name: "index_whatsapp_numbers_on_phone_number", unique: true
    t.index ["user_id"], name: "index_whatsapp_numbers_on_user_id"
  end

  add_foreign_key "calendar_configs", "users"
  add_foreign_key "conversations", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "whatsapp_numbers", "users"
end
