module Api
  module V1
    class CollectionsController < StoreScopedController
      def index
        authorize @store, :show?
        collections = @store.collections.includes(:collection_products).order(:id)
        render json: { collections: collections.map { |collection| CommerceJson.collection(collection) } }
      end

      def create
        require_catalog_editor
        collection = CollectionWriter.create(
          store: @store, actor: current_user, title: params.require(:title),
          handle: params.require(:handle), ip_address: request.remote_ip
        )
        render json: { collection: CommerceJson.collection(collection) }, status: :created
      end

      def add_product
        require_catalog_editor
        collection = @store.collections.find(params[:id])
        product = @store.products.find(params.require(:product_id))
        CollectionWriter.add_product(collection: collection, actor: current_user, product: product, ip_address: request.remote_ip)
        render json: { collection: CommerceJson.collection(collection.reload) }
      end
    end
  end
end
