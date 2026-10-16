class PriceQuote
  Line = Data.define(:variant, :quantity, :unit_price_cents, :line_total_cents)
  Result = Data.define(:lines, :subtotal_cents, :discount_cents, :shipping_cents, :tax_cents, :total_cents, :discount_code, :shipping_rate)

  def self.call(store:, cart_lines:, shipping_rate_id:, discount_code:)
    lines = cart_lines.map do |cart_line|
      variant = cart_line.variant
      unless variant.for_sale? && variant.store_id == store.id
        raise DomainError.new("not_for_sale", "A cart line is no longer for sale")
      end

      unit = variant.price_cents
      Line.new(variant: variant, quantity: cart_line.quantity, unit_price_cents: unit, line_total_cents: unit * cart_line.quantity)
    end
    raise DomainError.new("empty_cart", "The cart is empty") if lines.empty?

    subtotal = lines.sum(&:line_total_cents)
    discount_cents, applied_code = discount_for(store, discount_code, subtotal)
    shipping = ShippingRate.find_by(id: shipping_rate_id, store: store, status: "active")
    raise DomainError.new("not_found", "Shipping rate not found", status: :not_found) if shipping.nil?

    taxable = subtotal - discount_cents
    tax_rate = TaxRate.where(store: store, status: "active").order(:id).first
    tax = tax_rate ? (taxable * tax_rate.rate_bps) / 10_000 : 0
    total = taxable + shipping.price_cents + tax
    Result.new(
      lines: lines,
      subtotal_cents: subtotal,
      discount_cents: discount_cents,
      shipping_cents: shipping.price_cents,
      tax_cents: tax,
      total_cents: total,
      discount_code: applied_code,
      shipping_rate: shipping
    )
  end

  def self.discount_for(store, code, subtotal)
    return [ 0, nil ] if code.blank?

    discount = DiscountCode.find_by(store: store, code: code.to_s.strip.upcase, status: "active")
    raise DomainError.new("invalid_discount", "Discount code is not valid") if discount.nil?

    amount = if discount.kind == "percent"
      (subtotal * discount.percent_bps) / 10_000
    else
      [ discount.amount_cents, subtotal ].min
    end
    [ amount, discount.code ]
  end
end
