class FulfillmentTransition
  def self.call(order:, actor:, status:, tracking_number: nil, ip_address: nil)
    fulfillment = order.fulfillment
    allowed = Fulfillment::TRANSITIONS[fulfillment.status]
    unless allowed == status
      raise DomainError.new("invalid_transition", "Fulfillment can move from #{fulfillment.status} to #{allowed || "nowhere"}")
    end

    fulfillment.update!(status: status, tracking_number: tracking_number.presence || fulfillment.tracking_number)
    order.update!(fulfillment_status: status)
    EventRecorder.call(
      store: order.store, actor: actor, action: "fulfillment.updated", subject: fulfillment,
      metadata: { "number" => order.number, "status" => status }, ip_address: ip_address
    )
    fulfillment
  end
end
