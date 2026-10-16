module Api
  module V1
    class VariantsController < StoreScopedController
      before_action :require_catalog_editor

      def create
        variant = VariantWriter.create(
          product: find_product,
          actor: current_user,
          title: params.require(:title),
          sku: params.require(:sku),
          price_cents: params.require(:price_cents),
          on_hand: params.fetch(:on_hand, 0),
          ip_address: request.remote_ip
        )
        render json: { variant: CommerceJson.variant(variant.reload) }, status: :created
      end

      def update
        variant = VariantWriter.update(
          variant: find_variant,
          actor: current_user,
          title: params[:title],
          price_cents: params[:price_cents],
          status: params[:status],
          ip_address: request.remote_ip
        )
        render json: { variant: CommerceJson.variant(variant) }
      end

      private
        def find_product
          @store.products.find(params[:product_id])
        end

        def find_variant
          find_product.variants.find(params[:id])
        end
    end
  end
end
