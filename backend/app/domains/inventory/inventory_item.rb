class InventoryItem < ApplicationRecord
  belongs_to :store
  belongs_to :variant
  has_many :stock_movements, dependent: :restrict_with_exception

  validates :on_hand, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :variant_belongs_to_store

  private
    def variant_belongs_to_store
      return if variant.nil? || variant.store_id == store_id

      errors.add(:variant, "must belong to the same store")
    end
end
