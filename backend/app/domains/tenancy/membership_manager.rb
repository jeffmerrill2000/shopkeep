class MembershipManager
  def self.add(store:, actor:, email:, role:, ip_address: nil)
    ensure_owner!(actor, store)
    assignable!(role)
    user = User.find_by(email: email.to_s.strip.downcase)
    raise DomainError.new("unknown_user", "No account exists for that email") if user.nil?
    if Membership.exists?(user: user, store: store)
      raise DomainError.new("already_member", "That account is already a member of this store")
    end

    membership = Membership.create!(user: user, store: store, role: role)
    EventRecorder.call(
      store: store,
      actor: actor,
      action: "membership.created",
      subject: membership,
      metadata: { "role" => role, "member_email" => user.email },
      ip_address: ip_address
    )
    membership
  end

  def self.change_role(membership:, actor:, role:, ip_address: nil)
    ensure_owner!(actor, membership.store)
    assignable!(role)
    if membership.role == "owner"
      raise DomainError.new("owner_required", "The store owner role cannot be changed")
    end

    membership.update!(role: role)
    EventRecorder.call(
      store: membership.store,
      actor: actor,
      action: "membership.updated",
      subject: membership,
      metadata: { "role" => role, "member_email" => membership.user.email },
      ip_address: ip_address
    )
    membership
  end

  def self.remove(membership:, actor:, ip_address: nil)
    ensure_owner!(actor, membership.store)
    if membership.role == "owner"
      raise DomainError.new("owner_required", "The store owner cannot be removed")
    end

    EventRecorder.call(
      store: membership.store,
      actor: actor,
      action: "membership.removed",
      subject: membership,
      metadata: { "role" => membership.role, "member_email" => membership.user.email },
      ip_address: ip_address
    )
    membership.destroy!
  end

  def self.ensure_owner!(actor, store)
    return if Membership.exists?(user: actor, store: store, role: "owner")

    raise DomainError.new("forbidden", "Only an owner can manage memberships", status: :forbidden)
  end
  private_class_method :ensure_owner!

  def self.assignable!(role)
    return if Membership::ASSIGNABLE_ROLES.include?(role)

    raise DomainError.new("invalid_role", "Role must be admin or staff")
  end
  private_class_method :assignable!
end
