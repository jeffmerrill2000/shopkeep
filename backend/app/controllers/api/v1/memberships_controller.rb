module Api
  module V1
    class MembershipsController < ApplicationController
      before_action :set_member_store

      def index
        authorize @store, :show?
        memberships = @store.memberships.includes(:user).order(:id)
        render json: { memberships: memberships.map { |membership| JsonResponse.membership(membership) } }
      end

      def create
        authorize @store, :manage_memberships?
        membership = MembershipManager.add(
          store: @store,
          actor: current_user,
          email: params.require(:email),
          role: params.require(:role),
          ip_address: request.remote_ip
        )
        render json: { membership: JsonResponse.membership(membership) }, status: :created
      end

      def update
        membership = @store.memberships.find(params[:id])
        authorize @store, :manage_memberships?
        MembershipManager.change_role(
          membership: membership,
          actor: current_user,
          role: params.require(:role),
          ip_address: request.remote_ip
        )
        render json: { membership: JsonResponse.membership(membership) }
      end

      def destroy
        membership = @store.memberships.find(params[:id])
        authorize @store, :manage_memberships?
        MembershipManager.remove(membership: membership, actor: current_user, ip_address: request.remote_ip)
        head :no_content
      end

      private
        def set_member_store
          @membership = current_user.memberships.find_by(store_id: params[:store_id])
          raise ActiveRecord::RecordNotFound if @membership.nil?

          @store = @membership.store
        end
    end
  end
end
