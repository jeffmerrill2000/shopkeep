class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :stores, through: :memberships

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.strip }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 12 }, if: -> { password.present? }
end
