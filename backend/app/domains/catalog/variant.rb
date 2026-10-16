class Variant < ApplicationRecord
  STATUSES = %w[active archived].freeze

  belongs_to :store
  belongs_to :product
  has_one :inventory_item, dependent: :restrict_with_exception
  has_many :cart_lines, dependent: :restrict_with_exception
  has_many :order_lines, dependent: :restrict_with_exception

  normalizes :sku, with: ->(sku) { sku.to_s.strip.upcase }
  normalizes :title, with: ->(title) { title.to_s.strip }

  validates :title, presence: true
  validates :sku, presence: true, uniqueness: { scope: :store_id }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
  validate :product_belongs_to_store

  def for_sale?
    status == "active" && product.listed?
  end

  private
    def product_belongs_to_store
      return if product.nil? || product.store_id == store_id

      errors.add(:product, "must belong to the same store")
    end
end
