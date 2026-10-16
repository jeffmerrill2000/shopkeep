Rack::Attack.enabled = !Rails.env.test?
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.test?

# Production stays at 5 attempts per minute. Development is looser so the local
# browser suite can sign in from one machine without tripping the throttle.
identity_limit = Rails.env.development? ? 30 : 5
Rack::Attack.throttle("identity/ip", limit: identity_limit, period: 60) do |request|
  request.ip if request.post? && %w[/api/v1/session /api/v1/registration].include?(request.path)
end

Rack::Attack.throttled_responder = lambda do |_request|
  body = {
    error: {
      code: "rate_limited",
      message: "Too many attempts. Try again later.",
      details: {}
    }
  }
  [ 429, { "Content-Type" => "application/json" }, [ body.to_json ] ]
end
