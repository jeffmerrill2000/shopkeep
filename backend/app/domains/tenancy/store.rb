class Store < ApplicationRecord
  HANDLE_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
  CURRENCY_FORMAT = /\A[A-Z]{3}\z/

  belongs_to :merchant
  has_many :memberships, dependent: :restrict_with_exception
  has_many :audit_events, dependent: :restrict_with_exception
  has_many :products, dependent: :restrict_with_exception
  has_many :variants, dependent: :restrict_with_exception
  has_many :collections, dependent: :restrict_with_exception
  has_many :inventory_items, dependent: :restrict_with_exception
  has_many :discount_codes, dependent: :restrict_with_exception
  has_many :shipping_rates, dependent: :restrict_with_exception
  has_many :tax_rates, dependent: :restrict_with_exception
  has_many :carts, dependent: :restrict_with_exception
  has_many :customers, dependent: :restrict_with_exception
  has_many :orders, dependent: :restrict_with_exception

  normalizes :handle, with: ->(handle) { handle.to_s.strip.downcase }
  normalizes :name, with: ->(name) { name.to_s.strip }
  normalizes :currency, with: ->(currency) { currency.to_s.strip.upcase }

  validates :name, presence: true
  validates :handle, presence: true, uniqueness: true, format: { with: HANDLE_FORMAT }
  validates :currency, format: { with: CURRENCY_FORMAT }
  validates :status, inclusion: { in: %w[active suspended] }
end
