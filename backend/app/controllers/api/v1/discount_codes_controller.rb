module Api
  module V1
    class DiscountCodesController < StoreScopedController
      def index
        authorize @store, :show?
        render json: { discount_codes: @store.discount_codes.order(:id).map { |code| CommerceJson.discount_code(code) } }
      end

      def create
        require_catalog_editor
        code = DiscountCode.create!(
          store: @store,
          code: params.require(:code),
          kind: params.require(:kind),
          percent_bps: params[:kind] == "percent" ? MoneyCents.parse(params.require(:percent_bps)) : nil,
          amount_cents: params[:kind] == "amount" ? MoneyCents.parse(params.require(:amount_cents)) : nil,
          status: "active"
        )
        render json: { discount_code: CommerceJson.discount_code(code) }, status: :created
      end
    end
  end
end
