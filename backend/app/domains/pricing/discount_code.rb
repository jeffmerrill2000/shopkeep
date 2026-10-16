class DiscountCode < ApplicationRecord
  KINDS = %w[percent amount].freeze

  belongs_to :store

  normalizes :code, with: ->(code) { code.to_s.strip.upcase }

  validates :code, presence: true, uniqueness: { scope: :store_id }
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: %w[active inactive] }
  validates :percent_bps, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10_000 }, if: -> { kind == "percent" }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }, if: -> { kind == "amount" }
end
