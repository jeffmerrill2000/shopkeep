module Api
  module V1
    class HealthController < ApplicationController
      allow_unauthenticated_access

      def show
        report = Health::Check.call
        render json: report, status: report[:status] == "ok" ? :ok : :service_unavailable
      end
    end
  end
end
