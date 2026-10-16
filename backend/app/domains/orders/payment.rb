class Payment < ApplicationRecord
  belongs_to :store
  belongs_to :order

  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[succeeded] }
  validates :simulated, inclusion: { in: [ true ] }
end
