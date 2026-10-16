module Api
  module V1
    class StoresController < ApplicationController
      before_action :set_member_store, only: %i[show update]

      def index
        authorize Store
        render json: { stores: JsonResponse.stores_for(current_user) }
      end

      def show
        authorize @store
        render json: { store: JsonResponse.store(@store, role: @membership.role) }
      end

      def create
        merchant = owned_merchant
        authorize merchant, :create_store?
        store = StoreCreator.call(
          actor: current_user,
          merchant: merchant,
          name: params.require(:name),
          handle: params.require(:handle),
          currency: params[:currency].presence || "USD",
          ip_address: request.remote_ip
        )
        render json: { store: JsonResponse.store(store, role: "owner") }, status: :created
      end

      def update
        authorize @store
        StoreUpdater.call(
          store: @store,
          actor: current_user,
          name: params[:name],
          currency: params[:currency],
          ip_address: request.remote_ip
        )
        render json: { store: JsonResponse.store(@store, role: @membership.role) }
      end

      private
        def set_member_store
          @membership = current_user.memberships.includes(:store).find_by(store_id: params[:id])
          raise ActiveRecord::RecordNotFound if @membership.nil?

          @store = @membership.store
        end

        def owned_merchant
          Merchant.joins(stores: :memberships)
            .where(memberships: { user_id: current_user.id, role: "owner" })
            .find(params.require(:merchant_id))
        end
    end
  end
end
