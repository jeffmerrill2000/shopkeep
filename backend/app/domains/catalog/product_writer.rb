class ProductWriter
  def self.create(store:, actor:, title:, handle:, description: "", sku:, price_cents:, on_hand: 0, ip_address: nil)
    ActiveRecord::Base.transaction do
      product = Product.create!(store: store, title: title, handle: handle, description: description, status: "active")
      VariantWriter.create(
        product: product,
        actor: actor,
        title: "Default",
        sku: sku,
        price_cents: price_cents,
        on_hand: on_hand,
        ip_address: ip_address,
        audit: false
      )
      EventRecorder.call(
        store: store, actor: actor, action: "product.created", subject: product,
        metadata: { "handle" => product.handle }, ip_address: ip_address
      )
      product
    end
  end

  def self.update(product:, actor:, title: nil, description: nil, status: nil, ip_address: nil)
    attributes = {}
    attributes[:title] = title if title.present?
    attributes[:description] = description unless description.nil?
    attributes[:status] = status if status.present?
    product.update!(attributes)
    EventRecorder.call(
      store: product.store, actor: actor, action: "product.updated", subject: product,
      metadata: { "changes" => product.previous_changes.slice("title", "status") }, ip_address: ip_address
    )
    product
  end

  def self.archive(product:, actor:, ip_address: nil)
    update(product: product, actor: actor, status: "archived", ip_address: ip_address)
  end
end
