require "rails_helper"

RSpec.describe "Store tenancy" do
  let(:password) { IdentityHelpers::PASSWORD }

  def owner_result
    register_account(email: "owner@shopkeep.test", handle: "demo", store_name: "Demo Store")
  end

  def other_result
    register_account(email: "other@shopkeep.test", handle: "other-store", store_name: "Other Store")
  end

  it "lists only stores the user belongs to and ignores a client store header" do
    own = owner_result
    other = other_result
    sign_in_as(own.user)

    get "/api/v1/stores", headers: { "X-Store-Id" => other.store.id.to_s }
    handles = response.parsed_body.fetch("stores").map { |store| store.fetch("handle") }
    expect(handles).to eq([ "demo" ])

    get "/api/v1/stores/#{other.store.id}"
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("error", "code")).to eq("not_found")
  end

  it "returns 403 when a member's role cannot change the store or its memberships" do
    own = owner_result
    staff = User.create!(email: "staff@shopkeep.test", name: "Staff", password: password)
    admin = User.create!(email: "admin@shopkeep.test", name: "Admin", password: password)
    MembershipManager.add(store: own.store, actor: own.user, email: staff.email, role: "staff")
    MembershipManager.add(store: own.store, actor: own.user, email: admin.email, role: "admin")

    sign_in_as(staff)
    patch "/api/v1/stores/#{own.store.id}", params: { name: "Renamed" }, as: :json
    expect(response).to have_http_status(:forbidden)
    expect(own.store.reload.name).to eq("Demo Store")

    get "/api/v1/stores/#{own.store.id}/memberships"
    expect(response).to have_http_status(:ok)

    post "/api/v1/stores/#{own.store.id}/memberships", params: { email: "admin@shopkeep.test", role: "staff" }, as: :json
    expect(response).to have_http_status(:forbidden)

    sign_in_as(admin)
    patch "/api/v1/stores/#{own.store.id}", params: { name: "Admin Name" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(own.store.reload.name).to eq("Admin Name")

    post "/api/v1/stores/#{own.store.id}/memberships", params: { email: "staff@shopkeep.test", role: "admin" }, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it "lets an owner manage admin and staff memberships but not a second owner" do
    own = owner_result
    member = User.create!(email: "member@shopkeep.test", name: "Member", password: password)
    sign_in_as(own.user)

    post "/api/v1/stores/#{own.store.id}/memberships", params: { email: member.email, role: "owner" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_role")

    post "/api/v1/stores/#{own.store.id}/memberships", params: { email: member.email, role: "staff" }, as: :json
    expect(response).to have_http_status(:created)
    membership_id = response.parsed_body.dig("membership", "id")

    patch "/api/v1/stores/#{own.store.id}/memberships/#{membership_id}", params: { role: "admin" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("membership", "role")).to eq("admin")

    delete "/api/v1/stores/#{own.store.id}/memberships/#{own.membership.id}"
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("owner_required")

    get "/api/v1/stores/#{own.store.id}/audit_events"
    actions = response.parsed_body.fetch("audit_events").map { |event| event.fetch("action") }
    expect(actions).to include("membership.created", "account.registered")
    expect(response.body).not_to include(password)
  end

  it "hides another merchant's memberships and audit events" do
    own = owner_result
    other = other_result
    sign_in_as(own.user)

    get "/api/v1/stores/#{other.store.id}/memberships"
    expect(response).to have_http_status(:not_found)

    get "/api/v1/stores/#{other.store.id}/audit_events"
    expect(response).to have_http_status(:not_found)

    post "/api/v1/stores", params: { merchant_id: other.merchant.id, name: "Stolen", handle: "stolen" }, as: :json
    expect(response).to have_http_status(:not_found)
    expect(Store.exists?(handle: "stolen")).to be(false)
  end

  it "lets an owner open a second store on their merchant" do
    own = owner_result
    sign_in_as(own.user)

    post "/api/v1/stores", params: { merchant_id: own.merchant.id, name: "Second", handle: "second-store", currency: "eur" }, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("store", "currency")).to eq("EUR")
    expect(response.parsed_body.dig("store", "role")).to eq("owner")
  end
end
