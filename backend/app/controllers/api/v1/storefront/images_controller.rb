module Api
  module V1
    module Storefront
      class ImagesController < BaseController
        def show
          image = ProductImage.joins(:product).find_by!(id: params[:id], store: @store, products: { status: "active" })
          send_data image.file_bytes, type: image.content_type, disposition: "inline"
        end
      end
    end
  end
end
