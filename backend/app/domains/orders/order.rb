class Order < ApplicationRecord
  belongs_to :store
  belongs_to :customer
  has_many :order_lines, dependent: :restrict_with_exception
  has_many :payments, dependent: :restrict_with_exception
  has_one :fulfillment, dependent: :restrict_with_exception
  has_many :stock_movements, dependent: :restrict_with_exception

  validates :number, :idempotency_key, :access_token, :email, :customer_name, :currency, presence: true
  validates :subtotal_cents, :discount_cents, :shipping_cents, :tax_cents, :total_cents,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :payment_status, inclusion: { in: %w[paid] }
  validates :fulfillment_status, inclusion: { in: %w[unfulfilled shipped delivered] }
end
