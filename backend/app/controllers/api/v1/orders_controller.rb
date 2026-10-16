module Api
  module V1
    class OrdersController < StoreScopedController
      def index
        authorize @store, :show?
        orders = @store.orders.includes(:order_lines).order(id: :desc).limit(100)
        render json: { orders: orders.map { |order| CommerceJson.order(order) } }
      end

      def show
        authorize @store, :show?
        render json: { order: CommerceJson.order(@store.orders.includes(:order_lines).find(params[:id])) }
      end

      def fulfillment
        require_catalog_editor
        order = @store.orders.find(params[:id])
        FulfillmentTransition.call(
          order: order,
          actor: current_user,
          status: params.require(:status),
          tracking_number: params[:tracking_number],
          ip_address: request.remote_ip
        )
        render json: { order: CommerceJson.order(order.reload) }
      end
    end
  end
end
