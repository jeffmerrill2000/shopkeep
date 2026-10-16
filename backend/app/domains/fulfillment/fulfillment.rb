class Fulfillment < ApplicationRecord
  STATUSES = %w[unfulfilled shipped delivered].freeze
  TRANSITIONS = { "unfulfilled" => "shipped", "shipped" => "delivered" }.freeze

  belongs_to :store
  belongs_to :order

  validates :status, inclusion: { in: STATUSES }
end
