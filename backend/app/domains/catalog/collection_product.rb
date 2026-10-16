class CollectionProduct < ApplicationRecord
  belongs_to :store
  belongs_to :collection
  belongs_to :product

  validates :product_id, uniqueness: { scope: :collection_id }
  validate :same_store

  private
    def same_store
      return if collection.nil? || product.nil?
      return if collection.store_id == store_id && product.store_id == store_id

      errors.add(:product, "must belong to the same store")
    end
end
