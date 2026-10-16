class VariantWriter
  def self.create(product:, actor:, title:, sku:, price_cents:, on_hand: 0, ip_address: nil, audit: true)
    cents = MoneyCents.parse(price_cents)
    quantity = MoneyCents.parse(on_hand)
    variant = Variant.create!(
      store: product.store, product: product, title: title, sku: sku, price_cents: cents, status: "active"
    )
    item = InventoryItem.create!(store: product.store, variant: variant, on_hand: 0)
    InventoryAdjuster.call(item: item, actor: actor, delta: quantity, reason: "received", ip_address: ip_address) if quantity.positive?
    if audit
      EventRecorder.call(
        store: product.store, actor: actor, action: "variant.created", subject: variant,
        metadata: { "sku" => variant.sku, "price_cents" => cents }, ip_address: ip_address
      )
    end
    variant
  end

  def self.update(variant:, actor:, title: nil, price_cents: nil, status: nil, ip_address: nil)
    attributes = {}
    attributes[:title] = title if title.present?
    attributes[:price_cents] = MoneyCents.parse(price_cents) unless price_cents.nil?
    attributes[:status] = status if status.present?
    variant.update!(attributes)
    EventRecorder.call(
      store: variant.store, actor: actor, action: "variant.updated", subject: variant,
      metadata: { "sku" => variant.sku, "price_cents" => variant.price_cents }, ip_address: ip_address
    )
    variant
  end
end
