class MerchantPolicy < ApplicationPolicy
  def create_store?
    Membership.joins(:store).exists?(user_id: user.id, role: "owner", stores: { merchant_id: record.id })
  end
end
