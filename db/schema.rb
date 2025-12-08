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

ActiveRecord::Schema[7.1].define(version: 2024_12_08_000003) do
  create_table "calendars", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "timezone", default: "UTC", null: false
    t.string "color"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_calendars_on_user_id_and_name"
    t.index ["user_id"], name: "index_calendars_on_user_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.string "location"
    t.boolean "all_day", default: false
    t.integer "calendar_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["calendar_id", "start_time"], name: "index_schedules_on_calendar_id_and_start_time"
    t.index ["calendar_id"], name: "index_schedules_on_calendar_id"
    t.index ["end_time"], name: "index_schedules_on_end_time"
    t.index ["start_time"], name: "index_schedules_on_start_time"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "calendars", "users"
  add_foreign_key "schedules", "calendars"
end
