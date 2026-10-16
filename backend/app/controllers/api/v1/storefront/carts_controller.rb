module Api
  module V1
    module Storefront
      class CartsController < BaseController
        include StorefrontCart

        def show
          render json: { cart: CommerceJson.cart(current_public_cart) }
        end
      end
    end
  end
end
