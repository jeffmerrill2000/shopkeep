module JsonResponse
  module_function

  def user(user)
    { id: user.id, email: user.email, name: user.name }
  end

  def store(store, role:)
    {
      id: store.id,
      merchant_id: store.merchant_id,
      name: store.name,
      handle: store.handle,
      currency: store.currency.to_s.strip,
      status: store.status,
      role: role
    }
  end

  def stores_for(user)
    user.memberships.includes(:store).order(:id).map do |membership|
      store(membership.store, role: membership.role)
    end
  end

  def membership(membership)
    {
      id: membership.id,
      user_id: membership.user_id,
      email: membership.user.email,
      name: membership.user.name,
      role: membership.role
    }
  end

  def audit_event(event)
    {
      id: event.id,
      action: event.action,
      actor_id: event.actor_id,
      subject_type: event.subject_type,
      subject_id: event.subject_id,
      metadata: event.metadata,
      ip_address: event.ip_address,
      created_at: event.created_at.iso8601
    }
  end
end
