class Customer < ApplicationRecord
  belongs_to :store
  has_many :orders, dependent: :restrict_with_exception

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }
  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { scope: :store_id }
end
