class OrderLine < ApplicationRecord
  belongs_to :store
  belongs_to :order
  belongs_to :variant

  validates :sku, :title, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_cents, :line_total_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
