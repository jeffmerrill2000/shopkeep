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

ActiveRecord::Schema[8.1].define(version: 2026_10_15_203000) do
  create_table "audit_events", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "actor_id"
    t.string "action", null: false
    t.string "subject_type"
    t.bigint "subject_id"
    t.json "metadata", null: false
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_audit_events_on_actor_id"
    t.index ["store_id", "created_at"], name: "index_audit_events_on_store_id_and_created_at"
    t.index ["store_id"], name: "index_audit_events_on_store_id"
  end

  create_table "cart_lines", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "cart_id", null: false
    t.bigint "variant_id", null: false
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "variant_id"], name: "index_cart_lines_on_cart_id_and_variant_id", unique: true
    t.index ["cart_id"], name: "index_cart_lines_on_cart_id"
    t.index ["store_id"], name: "index_cart_lines_on_store_id"
    t.index ["variant_id"], name: "index_cart_lines_on_variant_id"
  end

  create_table "carts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "token", null: false
    t.string "status", default: "open", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_carts_on_store_id"
    t.index ["token"], name: "index_carts_on_token", unique: true
  end

  create_table "collection_products", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "collection_id", null: false
    t.bigint "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "product_id"], name: "index_collection_products_on_collection_id_and_product_id", unique: true
    t.index ["collection_id"], name: "index_collection_products_on_collection_id"
    t.index ["product_id"], name: "index_collection_products_on_product_id"
    t.index ["store_id"], name: "index_collection_products_on_store_id"
  end

  create_table "collections", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "title", null: false
    t.string "handle", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id", "handle"], name: "index_collections_on_store_id_and_handle", unique: true
    t.index ["store_id"], name: "index_collections_on_store_id"
  end

  create_table "customers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id", "email"], name: "index_customers_on_store_id_and_email", unique: true
    t.index ["store_id"], name: "index_customers_on_store_id"
  end

  create_table "discount_codes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "code", null: false
    t.string "kind", null: false
    t.integer "percent_bps"
    t.bigint "amount_cents"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id", "code"], name: "index_discount_codes_on_store_id_and_code", unique: true
    t.index ["store_id"], name: "index_discount_codes_on_store_id"
  end

  create_table "fulfillments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "order_id", null: false
    t.string "status", null: false
    t.string "tracking_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_fulfillments_on_order_id"
    t.index ["store_id"], name: "index_fulfillments_on_store_id"
  end

  create_table "inventory_items", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "variant_id", null: false
    t.integer "on_hand", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_inventory_items_on_store_id"
    t.index ["variant_id"], name: "index_inventory_items_on_variant_id", unique: true
  end

  create_table "memberships", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "store_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id", "role"], name: "index_memberships_on_store_id_and_role"
    t.index ["store_id"], name: "index_memberships_on_store_id"
    t.index ["user_id", "store_id"], name: "index_memberships_on_user_id_and_store_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "merchants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_lines", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "order_id", null: false
    t.bigint "variant_id", null: false
    t.string "sku", null: false
    t.string "title", null: false
    t.integer "quantity", null: false
    t.bigint "unit_price_cents", null: false
    t.bigint "line_total_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_lines_on_order_id"
    t.index ["store_id"], name: "index_order_lines_on_store_id"
    t.index ["variant_id"], name: "index_order_lines_on_variant_id"
  end

  create_table "orders", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "customer_id", null: false
    t.string "number", null: false
    t.string "idempotency_key", null: false
    t.string "access_token", null: false
    t.string "email", null: false
    t.string "customer_name", null: false
    t.bigint "subtotal_cents", null: false
    t.bigint "discount_cents", null: false
    t.bigint "shipping_cents", null: false
    t.bigint "tax_cents", null: false
    t.bigint "total_cents", null: false
    t.string "currency", limit: 3, null: false
    t.string "discount_code"
    t.json "shipping_address", null: false
    t.string "payment_status", null: false
    t.string "fulfillment_status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_orders_on_access_token", unique: true
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["store_id", "created_at"], name: "index_orders_on_store_id_and_created_at"
    t.index ["store_id", "idempotency_key"], name: "index_orders_on_store_id_and_idempotency_key", unique: true
    t.index ["store_id", "number"], name: "index_orders_on_store_id_and_number", unique: true
    t.index ["store_id"], name: "index_orders_on_store_id"
  end

  create_table "outbox_events", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "event_type", null: false
    t.json "payload", null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at", "id"], name: "index_outbox_events_on_published_at_and_id"
    t.index ["store_id"], name: "index_outbox_events_on_store_id"
  end

  create_table "payments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "order_id", null: false
    t.bigint "amount_cents", null: false
    t.string "status", null: false
    t.boolean "simulated", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.index ["store_id"], name: "index_payments_on_store_id"
  end

  create_table "product_images", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "product_id", null: false
    t.string "storage_key", null: false
    t.string "content_type", null: false
    t.string "alt_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_images_on_product_id"
    t.index ["storage_key"], name: "index_product_images_on_storage_key", unique: true
    t.index ["store_id"], name: "index_product_images_on_store_id"
  end

  create_table "products", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "title", null: false
    t.string "handle", null: false
    t.text "description", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id", "handle"], name: "index_products_on_store_id_and_handle", unique: true
    t.index ["store_id"], name: "index_products_on_store_id"
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shipping_rates", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "name", null: false
    t.bigint "price_cents", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_shipping_rates_on_store_id"
  end

  create_table "stock_movements", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "inventory_item_id", null: false
    t.integer "delta", null: false
    t.string "reason", null: false
    t.string "note"
    t.bigint "actor_id"
    t.bigint "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_stock_movements_on_actor_id"
    t.index ["inventory_item_id"], name: "index_stock_movements_on_inventory_item_id"
    t.index ["order_id"], name: "fk_rails_a739cce371"
    t.index ["store_id", "created_at"], name: "index_stock_movements_on_store_id_and_created_at"
    t.index ["store_id"], name: "index_stock_movements_on_store_id"
  end

  create_table "stores", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "merchant_id", null: false
    t.string "name", null: false
    t.string "handle", null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["handle"], name: "index_stores_on_handle", unique: true
    t.index ["merchant_id"], name: "index_stores_on_merchant_id"
  end

  create_table "tax_rates", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "name", null: false
    t.integer "rate_bps", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_tax_rates_on_store_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "variants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "product_id", null: false
    t.string "title", null: false
    t.string "sku", null: false
    t.bigint "price_cents", null: false
    t.string "status", default: "active", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_variants_on_product_id"
    t.index ["store_id", "sku"], name: "index_variants_on_store_id_and_sku", unique: true
    t.index ["store_id"], name: "index_variants_on_store_id"
  end

  add_foreign_key "audit_events", "stores"
  add_foreign_key "audit_events", "users", column: "actor_id"
  add_foreign_key "cart_lines", "carts"
  add_foreign_key "cart_lines", "stores"
  add_foreign_key "cart_lines", "variants"
  add_foreign_key "carts", "stores"
  add_foreign_key "collection_products", "collections"
  add_foreign_key "collection_products", "products"
  add_foreign_key "collection_products", "stores"
  add_foreign_key "collections", "stores"
  add_foreign_key "customers", "stores"
  add_foreign_key "discount_codes", "stores"
  add_foreign_key "fulfillments", "orders"
  add_foreign_key "fulfillments", "stores"
  add_foreign_key "inventory_items", "stores"
  add_foreign_key "inventory_items", "variants"
  add_foreign_key "memberships", "stores"
  add_foreign_key "memberships", "users"
  add_foreign_key "order_lines", "orders"
  add_foreign_key "order_lines", "stores"
  add_foreign_key "order_lines", "variants"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "stores"
  add_foreign_key "outbox_events", "stores"
  add_foreign_key "payments", "orders"
  add_foreign_key "payments", "stores"
  add_foreign_key "product_images", "products"
  add_foreign_key "product_images", "stores"
  add_foreign_key "products", "stores"
  add_foreign_key "sessions", "users"
  add_foreign_key "shipping_rates", "stores"
  add_foreign_key "stock_movements", "inventory_items"
  add_foreign_key "stock_movements", "orders"
  add_foreign_key "stock_movements", "stores"
  add_foreign_key "stock_movements", "users", column: "actor_id"
  add_foreign_key "stores", "merchants"
  add_foreign_key "tax_rates", "stores"
  add_foreign_key "variants", "products"
  add_foreign_key "variants", "stores"
end
