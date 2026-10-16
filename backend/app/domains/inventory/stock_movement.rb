class StockMovement < ApplicationRecord
  REASONS = %w[received correction damage sale return].freeze

  belongs_to :store
  belongs_to :inventory_item
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :order, optional: true

  validates :delta, numericality: { only_integer: true, other_than: 0 }
  validates :reason, inclusion: { in: REASONS }
end
