class Merchant < ApplicationRecord
  has_many :stores, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :status, inclusion: { in: %w[active suspended] }
end
