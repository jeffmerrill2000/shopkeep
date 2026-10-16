require "rails_helper"

RSpec.describe "GET /api/v1/health" do
  it "reports the database and redis as ok" do
    get "/api/v1/health"

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body).to eq("status" => "ok", "database" => "ok", "redis" => "ok")
  end

  it "returns 503 when redis is unavailable" do
    allow(Health::Check).to receive(:redis_status).and_return("error")

    get "/api/v1/health"

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to include("status" => "error", "redis" => "error", "database" => "ok")
  end
end
