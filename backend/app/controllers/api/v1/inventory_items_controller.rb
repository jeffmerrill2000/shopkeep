module Api
  module V1
    class InventoryItemsController < StoreScopedController
      def index
        authorize @store, :show?
        items = @store.inventory_items.includes(variant: :product).order(:id)
        render json: { inventory_items: items.map { |item| CommerceJson.inventory_item(item) } }
      end

      def adjustments
        require_catalog_editor
        item = @store.inventory_items.find(params[:id])
        updated = InventoryAdjuster.call(
          item: item,
          actor: current_user,
          delta: params.require(:delta),
          reason: params.require(:reason),
          note: params[:note],
          ip_address: request.remote_ip
        )
        render json: { inventory_item: CommerceJson.inventory_item(updated.reload) }
      end
    end
  end
end
