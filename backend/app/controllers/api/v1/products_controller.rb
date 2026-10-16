module Api
  module V1
    class ProductsController < StoreScopedController
      def index
        authorize @store, :show?
        products = @store.products.includes(variants: :inventory_item, product_images: []).order(:id)
        render json: { products: products.map { |product| CommerceJson.product(product) } }
      end

      def show
        authorize @store, :show?
        render json: { product: CommerceJson.product(find_product) }
      end

      def create
        require_catalog_editor
        product = ProductWriter.create(
          store: @store,
          actor: current_user,
          title: params.require(:title),
          handle: params.require(:handle),
          description: params[:description].to_s,
          sku: params.require(:sku),
          price_cents: params.require(:price_cents),
          on_hand: params.fetch(:on_hand, 0),
          ip_address: request.remote_ip
        )
        render json: { product: CommerceJson.product(product.reload) }, status: :created
      end

      def update
        require_catalog_editor
        product = ProductWriter.update(
          product: find_product,
          actor: current_user,
          title: params[:title],
          description: params[:description],
          status: params[:status],
          ip_address: request.remote_ip
        )
        render json: { product: CommerceJson.product(product) }
      end

      def archive
        require_catalog_editor
        product = ProductWriter.archive(product: find_product, actor: current_user, ip_address: request.remote_ip)
        render json: { product: CommerceJson.product(product) }
      end

      private
        def find_product
          @store.products.find(params[:id])
        end
    end
  end
end
