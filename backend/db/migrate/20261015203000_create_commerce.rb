class CreateCommerce < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :store, null: false, foreign_key: true
      t.string :title, null: false
      t.string :handle, null: false
      t.text :description, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :products, [ :store_id, :handle ], unique: true

    create_table :variants do |t|
      t.references :store, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :title, null: false
      t.string :sku, null: false
      t.bigint :price_cents, null: false
      t.string :status, null: false, default: "active"
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :variants, [ :store_id, :sku ], unique: true

    create_table :product_images do |t|
      t.references :store, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :storage_key, null: false
      t.string :content_type, null: false
      t.string :alt_text
      t.timestamps
    end
    add_index :product_images, :storage_key, unique: true

    create_table :collections do |t|
      t.references :store, null: false, foreign_key: true
      t.string :title, null: false
      t.string :handle, null: false
      t.timestamps
    end
    add_index :collections, [ :store_id, :handle ], unique: true

    create_table :collection_products do |t|
      t.references :store, null: false, foreign_key: true
      t.references :collection, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.timestamps
    end
    add_index :collection_products, [ :collection_id, :product_id ], unique: true

    create_table :inventory_items do |t|
      t.references :store, null: false, foreign_key: true
      t.references :variant, null: false, foreign_key: true, index: { unique: true }
      t.integer :on_hand, null: false, default: 0
      t.timestamps
    end

    create_table :stock_movements do |t|
      t.references :store, null: false, foreign_key: true
      t.references :inventory_item, null: false, foreign_key: true
      t.integer :delta, null: false
      t.string :reason, null: false
      t.string :note
      t.references :actor, foreign_key: { to_table: :users }
      t.bigint :order_id
      t.timestamps
    end
    add_index :stock_movements, [ :store_id, :created_at ]

    create_table :discount_codes do |t|
      t.references :store, null: false, foreign_key: true
      t.string :code, null: false
      t.string :kind, null: false
      t.integer :percent_bps
      t.bigint :amount_cents
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :discount_codes, [ :store_id, :code ], unique: true

    create_table :shipping_rates do |t|
      t.references :store, null: false, foreign_key: true
      t.string :name, null: false
      t.bigint :price_cents, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end

    create_table :tax_rates do |t|
      t.references :store, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :rate_bps, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end

    create_table :carts do |t|
      t.references :store, null: false, foreign_key: true
      t.string :token, null: false
      t.string :status, null: false, default: "open"
      t.timestamps
    end
    add_index :carts, :token, unique: true

    create_table :cart_lines do |t|
      t.references :store, null: false, foreign_key: true
      t.references :cart, null: false, foreign_key: true
      t.references :variant, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.timestamps
    end
    add_index :cart_lines, [ :cart_id, :variant_id ], unique: true

    create_table :customers do |t|
      t.references :store, null: false, foreign_key: true
      t.string :email, null: false
      t.string :name, null: false
      t.timestamps
    end
    add_index :customers, [ :store_id, :email ], unique: true

    create_table :orders do |t|
      t.references :store, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :number, null: false
      t.string :idempotency_key, null: false
      t.string :access_token, null: false
      t.string :email, null: false
      t.string :customer_name, null: false
      t.bigint :subtotal_cents, null: false
      t.bigint :discount_cents, null: false
      t.bigint :shipping_cents, null: false
      t.bigint :tax_cents, null: false
      t.bigint :total_cents, null: false
      t.string :currency, limit: 3, null: false
      t.string :discount_code
      t.json :shipping_address, null: false
      t.string :payment_status, null: false
      t.string :fulfillment_status, null: false
      t.timestamps
    end
    add_index :orders, [ :store_id, :number ], unique: true
    add_index :orders, [ :store_id, :idempotency_key ], unique: true
    add_index :orders, :access_token, unique: true
    add_index :orders, [ :store_id, :created_at ]

    create_table :order_lines do |t|
      t.references :store, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.references :variant, null: false, foreign_key: true
      t.string :sku, null: false
      t.string :title, null: false
      t.integer :quantity, null: false
      t.bigint :unit_price_cents, null: false
      t.bigint :line_total_cents, null: false
      t.timestamps
    end

    create_table :payments do |t|
      t.references :store, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.bigint :amount_cents, null: false
      t.string :status, null: false
      t.boolean :simulated, null: false, default: true
      t.timestamps
    end

    create_table :fulfillments do |t|
      t.references :store, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.string :status, null: false
      t.string :tracking_number
      t.timestamps
    end

    create_table :outbox_events do |t|
      t.references :store, null: false, foreign_key: true
      t.string :event_type, null: false
      t.json :payload, null: false
      t.datetime :published_at
      t.timestamps
    end
    add_index :outbox_events, [ :published_at, :id ]

    add_foreign_key :stock_movements, :orders
  end
end
