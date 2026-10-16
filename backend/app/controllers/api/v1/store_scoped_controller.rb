module Api
  module V1
    class StoreScopedController < ApplicationController
      before_action :set_member_store

      private
        def set_member_store
          @membership = current_user.memberships.find_by(store_id: params[:store_id])
          raise ActiveRecord::RecordNotFound if @membership.nil?

          @store = @membership.store
        end

        def require_catalog_editor
          authorize @store, :update?
        end
    end
  end
end
