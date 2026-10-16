module Api
  module V1
    module Storefront
      class BaseController < ApplicationController
        allow_unauthenticated_access
        before_action :set_public_store

        private
          def set_public_store
            @store = Store.find_by!(handle: params[:handle], status: "active")
          end
      end
    end
  end
end
