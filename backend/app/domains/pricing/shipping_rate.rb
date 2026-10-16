class ShippingRate < ApplicationRecord
  belongs_to :store

  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[active inactive] }
end
