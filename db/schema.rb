# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161122160702) do

  create_table "products", force: :cascade do |t|
    t.string   "code",       limit: 255
    t.string   "brand",      limit: 255
    t.string   "model",      limit: 255
    t.string   "type",       limit: 255
    t.string   "notes",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "reviews", force: :cascade do |t|
    t.text     "summary",        limit: 65535
    t.string   "pros",           limit: 255
    t.string   "cons",           limit: 255
    t.float    "starts",         limit: 24
    t.string   "recommendation", limit: 255
    t.integer  "useful",         limit: 4
    t.integer  "not_useful",     limit: 4
    t.string   "author",         limit: 255
    t.integer  "product_id",     limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "reviews", ["product_id"], name: "index_reviews_on_product_id", using: :btree

  add_foreign_key "reviews", "products"
end
