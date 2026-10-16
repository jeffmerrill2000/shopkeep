module Api
  module V1
    class AuditEventsController < ApplicationController
      before_action :set_member_store

      def index
        authorize @store, :show?
        events = AuditEvent.where(store: @store).order(created_at: :desc, id: :desc).limit(50)
        render json: { audit_events: events.map { |event| JsonResponse.audit_event(event) } }
      end

      private
        def set_member_store
          membership = current_user.memberships.find_by(store_id: params[:store_id])
          raise ActiveRecord::RecordNotFound if membership.nil?

          @store = membership.store
        end
    end
  end
end
