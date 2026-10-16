class Product < ApplicationRecord
  HANDLE = Store::HANDLE_FORMAT
  STATUSES = %w[active draft archived].freeze

  belongs_to :store
  has_many :variants, dependent: :restrict_with_exception
  has_many :product_images, dependent: :restrict_with_exception
  has_many :collection_products, dependent: :restrict_with_exception

  normalizes :handle, with: ->(handle) { handle.to_s.strip.downcase }
  normalizes :title, with: ->(title) { title.to_s.strip }

  validates :title, presence: true
  validates :description, length: { maximum: 10_000 }, allow_blank: true
  validates :handle, presence: true, format: { with: HANDLE }, uniqueness: { scope: :store_id }
  validates :status, inclusion: { in: STATUSES }

  scope :listed, -> { where(status: "active") }

  def listed?
    status == "active"
  end
end
