class CreateIdentityAndTenancy < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    create_table :merchants do |t|
      t.string :name, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end

    create_table :stores do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :handle, null: false
      t.column :currency, "char(3)", null: false, default: "USD"
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :stores, :handle, unique: true

    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.string :role, null: false
      t.timestamps
    end
    add_index :memberships, [ :user_id, :store_id ], unique: true
    add_index :memberships, [ :store_id, :role ]

    create_table :audit_events do |t|
      t.references :store, null: false, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :subject_type
      t.bigint :subject_id
      t.json :metadata, null: false
      t.string :ip_address
      t.timestamps
    end
    add_index :audit_events, [ :store_id, :created_at ]
  end
end
