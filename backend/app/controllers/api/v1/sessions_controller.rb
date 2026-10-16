module Api
  module V1
    class SessionsController < ApplicationController
      allow_unauthenticated_access only: :create

      def create
        user = SessionLogin.authenticate(email: params[:email], password: params[:password])
        if user.nil?
          render_error("invalid_credentials", "Email or password is incorrect", :unauthorized)
          return
        end

        start_new_session_for(user)
        render json: { user: JsonResponse.user(user), stores: JsonResponse.stores_for(user) }
      end

      def destroy
        terminate_session
        head :no_content
      end
    end
  end
end
