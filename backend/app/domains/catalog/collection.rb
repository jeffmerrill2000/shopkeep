class Collection < ApplicationRecord
  belongs_to :store
  has_many :collection_products, dependent: :restrict_with_exception
  has_many :products, through: :collection_products

  normalizes :handle, with: ->(handle) { handle.to_s.strip.downcase }
  normalizes :title, with: ->(title) { title.to_s.strip }

  validates :title, presence: true
  validates :handle, presence: true, format: { with: Product::HANDLE }, uniqueness: { scope: :store_id }
end
