class SalesSummary
  def self.call(store:)
    orders = Order.where(store: store, payment_status: "paid")
    units = OrderLine.where(store: store, order_id: orders.select(:id)).sum(:quantity)
    {
      order_count: orders.count,
      paid_total_cents: orders.sum(:total_cents).to_i,
      units_sold: units.to_i
    }
  end
end
