class Cart < ApplicationRecord
  belongs_to :store
  has_many :cart_lines, dependent: :restrict_with_exception

  validates :token, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[open checked_out] }
end
