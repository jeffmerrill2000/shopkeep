class StoreUpdater
  def self.call(store:, actor:, name: nil, currency: nil, ip_address: nil)
    attributes = {}
    attributes[:name] = name if name.present?
    attributes[:currency] = currency if currency.present?
    store.update!(attributes)
    EventRecorder.call(
      store: store,
      actor: actor,
      action: "store.updated",
      subject: store,
      metadata: { "changes" => store.previous_changes.slice("name", "currency") },
      ip_address: ip_address
    )
    store
  end
end
