class TaxRate < ApplicationRecord
  belongs_to :store

  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true
  validates :rate_bps, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 }
  validates :status, inclusion: { in: %w[active inactive] }
end
