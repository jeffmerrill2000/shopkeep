class StoreCreator
  def self.call(actor:, merchant:, name:, handle:, currency:, ip_address: nil)
    unless Membership.joins(:store).exists?(user: actor, role: "owner", stores: { merchant_id: merchant.id })
      raise DomainError.new("not_found", "Merchant not found", status: :not_found)
    end

    ActiveRecord::Base.transaction do
      store = Store.create!(merchant: merchant, name: name, handle: handle, currency: currency)
      Membership.create!(user: actor, store: store, role: "owner")
      EventRecorder.call(
        store: store,
        actor: actor,
        action: "store.created",
        subject: store,
        metadata: { "handle" => store.handle, "currency" => store.currency.to_s.strip },
        ip_address: ip_address
      )
      store
    end
  end
end
