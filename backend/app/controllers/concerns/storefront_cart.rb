module StorefrontCart
  extend ActiveSupport::Concern

  private
    def current_public_cart
      token = cart_tokens[@store.id.to_s]
      return if token.blank?

      Cart.find_by(store: @store, token: token, status: "open")
    end

    def ensure_public_cart
      current_public_cart || create_public_cart
    end

    def create_public_cart
      cart = Cart.create!(store: @store, token: SecureRandom.urlsafe_base64(24), status: "open")
      tokens = cart_tokens
      tokens[@store.id.to_s] = cart.token
      cookies.signed.permanent[:shopkeep_carts] = {
        value: tokens.to_json,
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production?
      }
      cart
    end

    def cart_tokens
      raw = cookies.signed[:shopkeep_carts]
      parsed = raw.is_a?(String) ? JSON.parse(raw) : {}
      parsed.is_a?(Hash) ? parsed : {}
    rescue JSON::ParserError
      {}
    end
end
