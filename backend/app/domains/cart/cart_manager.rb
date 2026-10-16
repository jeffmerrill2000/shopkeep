class CartManager
  def self.add(cart:, variant:, quantity:)
    raise DomainError.new("not_for_sale", "That variant is not for sale") unless variant.for_sale?
    raise DomainError.new("not_found", "Variant not found", status: :not_found) if variant.store_id != cart.store_id

    amount = MoneyCents.parse(quantity)
    raise DomainError.new("invalid_amount", "Quantity must be at least 1") if amount < 1

    line = cart.cart_lines.find_or_initialize_by(variant: variant)
    line.store = cart.store
    line.quantity = line.quantity.to_i + amount
    raise DomainError.new("invalid_amount", "Quantity cannot exceed 100") if line.quantity > 100

    line.save!
    line
  end

  def self.update_quantity(line:, quantity:)
    amount = MoneyCents.parse(quantity)
    if amount.zero?
      line.destroy!
      return nil
    end

    line.update!(quantity: amount)
    line
  end
end
