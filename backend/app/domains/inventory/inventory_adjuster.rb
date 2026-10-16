class InventoryAdjuster
  def self.call(item:, actor:, delta:, reason:, note: nil, order: nil, ip_address: nil)
    change = delta.is_a?(Integer) ? delta : MoneyCents.parse_delta(delta)
    raise DomainError.new("invalid_amount", "Stock changes must be a non-zero integer") if change.zero?
    raise DomainError.new("invalid", "Unknown stock reason") unless StockMovement::REASONS.include?(reason)

    ActiveRecord::Base.transaction do
      locked = InventoryItem.lock.find(item.id)
      next_on_hand = locked.on_hand + change
      if next_on_hand.negative?
        raise DomainError.new("insufficient_stock", "That adjustment would make on-hand negative")
      end

      locked.update!(on_hand: next_on_hand)
      movement = StockMovement.create!(
        store: locked.store,
        inventory_item: locked,
        delta: change,
        reason: reason,
        note: note,
        actor: actor,
        order: order
      )
      if reason != "sale" && reason != "received" || actor.present? && reason != "sale"
        EventRecorder.call(
          store: locked.store, actor: actor, action: "inventory.adjusted", subject: movement,
          metadata: { "delta" => change, "reason" => reason, "on_hand" => next_on_hand },
          ip_address: ip_address
        )
      end
      locked
    end
  end
end
