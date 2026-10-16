module Api
  module V1
    module Storefront
      class ProductsController < BaseController
        def index
          products = @store.products.listed.includes(variants: :inventory_item, product_images: []).order(:id)
          render json: { products: products.map { |product| CommerceJson.product(product) } }
        end

        def show
          product = @store.products.listed.includes(variants: :inventory_item, product_images: []).find_by!(handle: params[:product_handle])
          render json: { product: CommerceJson.product(product) }
        end
      end
    end
  end
end
