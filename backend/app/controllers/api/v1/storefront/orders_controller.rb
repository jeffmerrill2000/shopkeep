module Api
  module V1
    module Storefront
      class OrdersController < BaseController
        def show
          order = @store.orders.find_by!(number: params[:number], access_token: params.require(:access_token))
          render json: { order: CommerceJson.order(order) }
        end
      end
    end
  end
end
