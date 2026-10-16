module Api
  module V1
    module Storefront
      class CartLinesController < BaseController
        include StorefrontCart

        def create
          variant = @store.variants.find(params.require(:variant_id))
          line = CartManager.add(cart: ensure_public_cart, variant: variant, quantity: params.require(:quantity))
          render json: { cart: CommerceJson.cart(line.cart.reload) }, status: :created
        end

        def update
          line = ensure_public_cart.cart_lines.find(params[:id])
          CartManager.update_quantity(line: line, quantity: params.require(:quantity))
          render json: { cart: CommerceJson.cart(current_public_cart) }
        end

        def destroy
          line = ensure_public_cart.cart_lines.find(params[:id])
          line.destroy!
          render json: { cart: CommerceJson.cart(current_public_cart) }
        end
      end
    end
  end
end
