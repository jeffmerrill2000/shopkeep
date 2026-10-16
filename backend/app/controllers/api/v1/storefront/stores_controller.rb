module Api
  module V1
    module Storefront
      class StoresController < BaseController
        def show
          products = @store.products.listed.includes(variants: :inventory_item, product_images: []).order(:id)
          render json: {
            store: { name: @store.name, handle: @store.handle, currency: @store.currency.to_s.strip },
            products: products.map { |product| CommerceJson.product(product) },
            shipping_rates: @store.shipping_rates.where(status: "active").order(:id).map { |rate| CommerceJson.shipping_rate(rate) },
            tax_rates: @store.tax_rates.where(status: "active").order(:id).map { |rate| CommerceJson.tax_rate(rate) }
          }
        end
      end
    end
  end
end
