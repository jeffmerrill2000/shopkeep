module CommerceJson
  module_function

  def product(product, include_variants: true)
    payload = {
      id: product.id,
      store_id: product.store_id,
      title: product.title,
      handle: product.handle,
      description: product.description,
      status: product.status
    }
    payload[:variants] = product.variants.order(:position, :id).map { |variant| variant(variant) } if include_variants
    payload[:images] = product.product_images.order(:id).map { |image| image(image) }
    payload
  end

  def variant(variant)
    {
      id: variant.id,
      product_id: variant.product_id,
      title: variant.title,
      sku: variant.sku,
      price_cents: variant.price_cents,
      status: variant.status,
      on_hand: variant.inventory_item&.on_hand
    }
  end

  def image(image)
    {
      id: image.id,
      product_id: image.product_id,
      alt_text: image.alt_text,
      content_type: image.content_type
    }
  end

  def collection(collection)
    {
      id: collection.id,
      title: collection.title,
      handle: collection.handle,
      product_ids: collection.collection_products.order(:id).pluck(:product_id)
    }
  end

  def inventory_item(item)
    {
      id: item.id,
      variant_id: item.variant_id,
      sku: item.variant.sku,
      product_title: item.variant.product.title,
      on_hand: item.on_hand
    }
  end

  def cart(cart)
    lines = cart.nil? ? [] : cart.cart_lines.includes(variant: :product).order(:id).map { |line| cart_line(line) }
    { id: cart&.id, lines: lines }
  end

  def cart_line(line)
    unit = line.variant.price_cents
    {
      id: line.id,
      variant_id: line.variant_id,
      sku: line.variant.sku,
      title: "#{line.variant.product.title} — #{line.variant.title}",
      quantity: line.quantity,
      unit_price_cents: unit,
      line_total_cents: unit * line.quantity,
      for_sale: line.variant.for_sale?
    }
  end

  def order(order, include_access_token: false)
    payload = {
      id: order.id,
      number: order.number,
      email: order.email,
      customer_name: order.customer_name,
      subtotal_cents: order.subtotal_cents,
      discount_cents: order.discount_cents,
      shipping_cents: order.shipping_cents,
      tax_cents: order.tax_cents,
      total_cents: order.total_cents,
      currency: order.currency.to_s.strip,
      discount_code: order.discount_code,
      payment_status: order.payment_status,
      fulfillment_status: order.fulfillment_status,
      simulated_payment: true,
      shipping_address: order.shipping_address,
      lines: order.order_lines.order(:id).map { |line| order_line(line) }
    }
    payload[:access_token] = order.access_token if include_access_token
    payload
  end

  def order_line(line)
    {
      id: line.id,
      sku: line.sku,
      title: line.title,
      quantity: line.quantity,
      unit_price_cents: line.unit_price_cents,
      line_total_cents: line.line_total_cents
    }
  end

  def customer(customer)
    { id: customer.id, email: customer.email, name: customer.name, order_count: customer.orders.size }
  end

  def shipping_rate(rate)
    { id: rate.id, name: rate.name, price_cents: rate.price_cents, status: rate.status }
  end

  def tax_rate(rate)
    { id: rate.id, name: rate.name, rate_bps: rate.rate_bps, status: rate.status }
  end

  def discount_code(code)
    {
      id: code.id,
      code: code.code,
      kind: code.kind,
      percent_bps: code.percent_bps,
      amount_cents: code.amount_cents,
      status: code.status
    }
  end
end
