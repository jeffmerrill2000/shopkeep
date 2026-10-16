module Api
  module V1
    class TaxRatesController < StoreScopedController
      def index
        authorize @store, :show?
        render json: { tax_rates: @store.tax_rates.order(:id).map { |rate| CommerceJson.tax_rate(rate) } }
      end

      def create
        require_catalog_editor
        rate = TaxRate.create!(
          store: @store,
          name: params.require(:name),
          rate_bps: MoneyCents.parse(params.require(:rate_bps)),
          status: "active"
        )
        render json: { tax_rate: CommerceJson.tax_rate(rate) }, status: :created
      end
    end
  end
end
