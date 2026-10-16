module Api
  module V1
    class MeController < ApplicationController
      def show
        render json: { user: JsonResponse.user(current_user), stores: JsonResponse.stores_for(current_user) }
      end
    end
  end
end
