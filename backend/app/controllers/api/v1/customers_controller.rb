module Api
  module V1
    class CustomersController < StoreScopedController
      def index
        authorize @store, :show?
        customers = @store.customers.includes(:orders).order(:id)
        render json: { customers: customers.map { |customer| CommerceJson.customer(customer) } }
      end

      def show
        authorize @store, :show?
        customer = @store.customers.includes(:orders).find(params[:id])
        render json: {
          customer: CommerceJson.customer(customer),
          orders: customer.orders.order(id: :desc).map { |order| CommerceJson.order(order) }
        }
      end
    end
  end
end
