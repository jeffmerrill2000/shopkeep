class Checkout
  def self.call(store:, cart:, email:, name:, address:, shipping_rate_id:, discount_code:, idempotency_key:, ip_address: nil)
    raise DomainError.new("invalid", "Idempotency-Key is required", status: :bad_request) if idempotency_key.blank?

    existing = Order.find_by(store: store, idempotency_key: idempotency_key)
    return existing if existing
    raise DomainError.new("empty_cart", "The cart is empty") if cart.nil?

    order = ActiveRecord::Base.transaction do
      locked_cart = Cart.lock.find(cart.id)
      raise DomainError.new("invalid_cart", "That cart is no longer open") unless locked_cart.status == "open" && locked_cart.store_id == store.id

      cart_lines = locked_cart.cart_lines.includes(variant: [ :product, :inventory_item ]).order(:id).to_a
      quote = PriceQuote.call(
        store: store,
        cart_lines: cart_lines,
        shipping_rate_id: shipping_rate_id,
        discount_code: discount_code
      )
      items = InventoryItem.where(store: store, variant_id: quote.lines.map { |line| line.variant.id }).order(:id).lock.to_a
      quote.lines.each do |line|
        item = items.find { |candidate| candidate.variant_id == line.variant.id }
        if item.nil? || item.on_hand < line.quantity
          raise DomainError.new("insufficient_stock", "Not enough inventory to complete checkout")
        end
      end

      customer = Customer.find_or_initialize_by(store: store, email: email)
      customer.name = name
      customer.save!
      order = Order.create!(
        store: store,
        customer: customer,
        number: "#{store.id}-#{SecureRandom.hex(4)}",
        idempotency_key: idempotency_key,
        access_token: SecureRandom.urlsafe_base64(24),
        email: customer.email,
        customer_name: customer.name,
        subtotal_cents: quote.subtotal_cents,
        discount_cents: quote.discount_cents,
        shipping_cents: quote.shipping_cents,
        tax_cents: quote.tax_cents,
        total_cents: quote.total_cents,
        currency: store.currency.to_s.strip,
        discount_code: quote.discount_code,
        shipping_address: address_snapshot(address),
        payment_status: "paid",
        fulfillment_status: "unfulfilled"
      )
      quote.lines.each do |line|
        OrderLine.create!(
          store: store,
          order: order,
          variant: line.variant,
          sku: line.variant.sku,
          title: "#{line.variant.product.title} — #{line.variant.title}",
          quantity: line.quantity,
          unit_price_cents: line.unit_price_cents,
          line_total_cents: line.line_total_cents
        )
        item = items.find { |candidate| candidate.variant_id == line.variant.id }
        InventoryAdjuster.call(item: item, actor: nil, delta: -line.quantity, reason: "sale", order: order, ip_address: ip_address)
      end
      Payment.create!(store: store, order: order, amount_cents: order.total_cents, status: "succeeded", simulated: true)
      Fulfillment.create!(store: store, order: order, status: "unfulfilled")
      record_outbox(order)
      EventRecorder.call(
        store: store, actor: nil, action: "order.created", subject: order,
        metadata: { "number" => order.number, "total_cents" => order.total_cents }, ip_address: ip_address
      )
      locked_cart.update!(status: "checked_out")
      order
    end
    OutboxDrainJob.perform_later
    order
  rescue ActiveRecord::RecordNotUnique
    Order.find_by!(store: store, idempotency_key: idempotency_key)
  end

  def self.address_snapshot(address)
    required = %w[line1 city region postal_code country]
    source = address.to_h.stringify_keys
    missing = required.reject { |key| source[key].present? }
    raise DomainError.new("invalid", "A complete shipping address is required", details: { "address" => missing }) if missing.any?

    source.slice(*required)
  end

  def self.record_outbox(order)
    payload = { "order_id" => order.id, "number" => order.number, "total_cents" => order.total_cents }
    OutboxEvent::TYPES.each do |event_type|
      OutboxEvent.create!(store: order.store, event_type: event_type, payload: payload)
    end
  end
end
