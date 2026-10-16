class StorePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    membership.present?
  end

  def update?
    %w[owner admin].include?(membership&.role)
  end

  def manage_memberships?
    membership&.role == "owner"
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:memberships).where(memberships: { user_id: user.id })
    end
  end

  private
    def membership
      return record if record.is_a?(Membership) && record.user_id == user.id

      @membership ||= Membership.find_by(user: user, store: record)
    end
end
