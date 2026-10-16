class CartLine < ApplicationRecord
  belongs_to :store
  belongs_to :cart
  belongs_to :variant

  validates :quantity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
  validate :same_store

  private
    def same_store
      return if cart.nil? || variant.nil?
      return if cart.store_id == store_id && variant.store_id == store_id

      errors.add(:variant, "must belong to the same store")
    end
end
