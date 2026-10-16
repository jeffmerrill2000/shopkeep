require "rails_helper"

RSpec.describe "CSRF" do
  let(:registration) do
    {
      email: "csrf@shopkeep.test",
      password: IdentityHelpers::PASSWORD,
      name: "CSRF Owner",
      store_name: "CSRF Store",
      handle: "csrf-store"
    }
  end

  around do |example|
    previous = ApplicationController.allow_forgery_protection
    ApplicationController.allow_forgery_protection = true
    example.run
  ensure
    ApplicationController.allow_forgery_protection = previous
  end

  it "rejects a mutation without the CSRF header" do
    post "/api/v1/registration", params: registration, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_csrf")
    expect(User.exists?(email: "csrf@shopkeep.test")).to be(false)
  end

  it "accepts the token issued by GET /api/v1/csrf" do
    get "/api/v1/csrf"
    expect(response).to have_http_status(:ok)
    token = response.parsed_body.fetch("csrf_token")

    post "/api/v1/registration",
      params: registration,
      headers: { "X-CSRF-Token" => token },
      as: :json

    expect(response).to have_http_status(:created)
  end
end
