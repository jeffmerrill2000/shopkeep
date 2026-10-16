module IdentityHelpers
  PASSWORD = "passwordpassword"

  def register_account(email:, handle:, name: "Store Owner", store_name: "Store")
    AccountRegistration.call(
      email: email,
      password: PASSWORD,
      name: name,
      store_name: store_name,
      handle: handle
    )
  end

  def sign_in_as(user, password: PASSWORD)
    post "/api/v1/session", params: { email: user.email, password: password }, as: :json
    expect(response).to have_http_status(:ok)
  end
end

RSpec.configure do |config|
  config.include IdentityHelpers, type: :request
end
