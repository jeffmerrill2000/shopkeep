module Api
  module V1
    class ShippingRatesController < StoreScopedController
      def index
        authorize @store, :show?
        render json: { shipping_rates: @store.shipping_rates.order(:id).map { |rate| CommerceJson.shipping_rate(rate) } }
      end

      def create
        require_catalog_editor
        rate = ShippingRate.create!(
          store: @store, name: params.require(:name), price_cents: MoneyCents.parse(params.require(:price_cents)), status: "active"
        )
        render json: { shipping_rate: CommerceJson.shipping_rate(rate) }, status: :created
      end
    end
  end
end
