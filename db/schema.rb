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

ActiveRecord::Schema[8.1].define(version: 2026_02_23_072529) do
  create_table "drug_products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name"
    t.boolean "is_temporary"
    t.datetime "updated_at", null: false
  end

  create_table "intake_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "medication_item_id", null: false
    t.integer "quantity_taken"
    t.datetime "taken_at"
    t.datetime "updated_at", null: false
    t.index ["medication_item_id"], name: "index_intake_logs_on_medication_item_id"
  end

  create_table "medication_items", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.integer "drug_product_id", null: false
    t.integer "person_id", null: false
    t.datetime "updated_at", null: false
    t.index ["drug_product_id"], name: "index_medication_items_on_drug_product_id"
    t.index ["person_id"], name: "index_medication_items_on_person_id"
  end

  create_table "medication_lots", force: :cascade do |t|
    t.date "base_date"
    t.datetime "created_at", null: false
    t.integer "medication_item_id", null: false
    t.integer "quantity_initial"
    t.integer "quantity_remaining"
    t.integer "shelf_life_days"
    t.datetime "updated_at", null: false
    t.index ["medication_item_id"], name: "index_medication_lots_on_medication_item_id"
  end

  create_table "people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "intake_logs", "medication_items"
  add_foreign_key "medication_items", "drug_products"
  add_foreign_key "medication_items", "people"
  add_foreign_key "medication_lots", "medication_items"
end
