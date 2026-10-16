require "rails_helper"

RSpec.describe "Identity rate limit" do
  around do |example|
    previous = Rack::Attack.enabled
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
    example.run
  ensure
    Rack::Attack.enabled = previous
    Rack::Attack.reset!
  end

  it "returns 429 after five login attempts from the same IP" do
    5.times do
      post "/api/v1/session", params: { email: "missing@shopkeep.test", password: "passwordpassword" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    post "/api/v1/session", params: { email: "missing@shopkeep.test", password: "passwordpassword" }, as: :json
    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body.dig("error", "code")).to eq("rate_limited")
  end
end
