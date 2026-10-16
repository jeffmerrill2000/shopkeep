module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def current_user
      Current.user
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      token = cookies.signed[:session_id]
      return if token.blank?

      Session.find_by(id: token)
    end

    def request_authentication
      render_error("unauthenticated", "Sign in required", :unauthorized)
    end

    def start_new_session_for(user)
      user.sessions.create!(ip_address: request.remote_ip, user_agent: request.user_agent).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = session_cookie_options(session.id)
      end
    end

    def terminate_session
      Current.session&.destroy
      Current.session = nil
      cookies.delete(:session_id, **session_cookie_delete_options)
    end

    def session_cookie_options(value)
      { value: value, httponly: true, same_site: :lax, secure: Rails.env.production? }
    end

    def session_cookie_delete_options
      { httponly: true, same_site: :lax, secure: Rails.env.production? }
    end
end
