class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  include Authentication
  include Pundit::Authorization

  protect_from_forgery with: :exception
  # API controllers do not inherit ActionController::Base's test-mode flag.
  self.allow_forgery_protection = Rails.application.config.action_controller.allow_forgery_protection

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_invalid_csrf
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  rescue_from DomainError, with: :render_domain_error

  private
    def render_error(code, message, status, details = {})
      render json: { error: { code: code, message: message, details: details } }, status: status
    end

    def render_forbidden(_exception = nil)
      render_error("forbidden", "You do not have access to do that", :forbidden)
    end

    def render_not_found(_exception = nil)
      render_error("not_found", "Not found", :not_found)
    end

    def render_invalid(exception)
      render_error("invalid", "Validation failed", :unprocessable_content, exception.record.errors.to_hash)
    end

    def render_invalid_csrf(_exception = nil)
      render_error("invalid_csrf", "CSRF token is missing or invalid", :unprocessable_content)
    end

    def render_parameter_missing(exception)
      render_error("invalid", exception.message, :bad_request)
    end

    def render_domain_error(exception)
      render_error(exception.code, exception.message, exception.status, exception.details)
    end

    def pundit_user
      current_user
    end
end
