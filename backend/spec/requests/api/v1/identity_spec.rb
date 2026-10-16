require "rails_helper"

RSpec.describe "Identity API" do
  let(:password) { IdentityHelpers::PASSWORD }
  let(:registration) do
    {
      email: "new@shopkeep.test",
      password: password,
      name: "New Owner",
      store_name: "New Store",
      handle: "new-store"
    }
  end

  it "registers and signs in without returning the password digest" do
    post "/api/v1/registration", params: registration, as: :json

    expect(response).to have_http_status(:created)
    body = response.parsed_body
    expect(body.dig("user", "email")).to eq("new@shopkeep.test")
    expect(body.dig("store", "handle")).to eq("new-store")
    expect(body.dig("store", "role")).to eq("owner")
    expect(response.body).not_to include("password_digest")
    expect(response.headers["Set-Cookie"]).to include("session_id")
    expect(response.headers["Set-Cookie"].downcase).to include("httponly")
    expect(response.headers["Set-Cookie"].downcase).to include("samesite=lax")

    get "/api/v1/me"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("user", "email")).to eq("new@shopkeep.test")
  end

  it "returns 422 and keeps the database unchanged for an invalid handle" do
    expect do
      post "/api/v1/registration", params: registration.merge(handle: "Bad Handle"), as: :json
    end.not_to change(User, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid")
    expect(Merchant.count).to eq(0)
  end

  it "rejects a wrong password and accepts the original email regardless of case" do
    post "/api/v1/registration", params: registration, as: :json

    post "/api/v1/session", params: { email: "new@shopkeep.test", password: "wrong-password-1" }, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_credentials")

    post "/api/v1/session", params: { email: "NEW@shopkeep.test", password: password }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("stores", 0, "handle")).to eq("new-store")
  end

  it "requires a session for the current user and ends it on sign out" do
    get "/api/v1/me"
    expect(response).to have_http_status(:unauthorized)

    post "/api/v1/registration", params: registration, as: :json
    delete "/api/v1/session"
    expect(response).to have_http_status(:no_content)

    get "/api/v1/me"
    expect(response).to have_http_status(:unauthorized)
  end
end
