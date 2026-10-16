class Membership < ApplicationRecord
  ROLES = %w[owner admin staff].freeze
  ASSIGNABLE_ROLES = %w[admin staff].freeze

  belongs_to :user
  belongs_to :store

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :store_id }
end
