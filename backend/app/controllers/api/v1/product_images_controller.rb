module Api
  module V1
    class ProductImagesController < StoreScopedController
      def create
        require_catalog_editor
        image = ImageAttacher.call(product: find_product, upload: params.require(:file), alt_text: params[:alt_text])
        render json: { image: CommerceJson.image(image) }, status: :created
      end

      def show
        authorize @store, :show?
        image = find_product.product_images.find(params[:id])
        send_data image.file_bytes, type: image.content_type, disposition: "inline"
      end

      private
        def find_product
          @store.products.find(params[:product_id])
        end
    end
  end
end
