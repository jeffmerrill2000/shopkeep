module Api
  module V1
    class SalesSummariesController < StoreScopedController
      def show
        authorize @store, :show?
        render json: { sales_summary: SalesSummary.call(store: @store) }
      end
    end
  end
end
