module Api
  module V1
    class RegistrationsController < ApplicationController
      allow_unauthenticated_access only: :create

      def create
        permitted = params.permit(:email, :password, :name, :store_name, :handle, :currency)
        result = AccountRegistration.call(
          email: permitted.require(:email),
          password: permitted.require(:password),
          name: permitted.require(:name),
          store_name: permitted.require(:store_name),
          handle: permitted.require(:handle),
          currency: permitted[:currency].presence || "USD",
          ip_address: request.remote_ip
        )
        start_new_session_for(result.user)
        render json: {
          user: JsonResponse.user(result.user),
          store: JsonResponse.store(result.store, role: "owner")
        }, status: :created
      end
    end
  end
end
