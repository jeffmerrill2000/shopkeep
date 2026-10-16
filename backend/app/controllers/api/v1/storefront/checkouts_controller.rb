module Api
  module V1
    module Storefront
      class CheckoutsController < BaseController
        include StorefrontCart

        def create
          order = Checkout.call(
            store: @store,
            cart: current_public_cart,
            email: params.require(:email),
            name: params.require(:name),
            address: params.require(:address).permit(:line1, :city, :region, :postal_code, :country).to_h,
            shipping_rate_id: params.require(:shipping_rate_id),
            discount_code: params[:discount_code],
            idempotency_key: request.headers["Idempotency-Key"],
            ip_address: request.remote_ip
          )
          render json: { order: CommerceJson.order(order, include_access_token: true) }, status: :created
        end
      end
    end
  end
end
