class OutboxEvent < ApplicationRecord
  TYPES = %w[OrderCreated PaymentRecorded InventoryAdjusted].freeze

  belongs_to :store

  validates :event_type, inclusion: { in: TYPES }
  validates :payload, exclusion: { in: [ nil ] }
end
