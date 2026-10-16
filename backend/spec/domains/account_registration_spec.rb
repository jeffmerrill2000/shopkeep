require "rails_helper"

RSpec.describe AccountRegistration do
  let(:password) { "passwordpassword" }

  def attributes(handle: "demo-store")
    {
      email: "owner@shopkeep.test",
      password: password,
      name: "Owner",
      store_name: "Demo",
      handle: handle
    }
  end

  it "creates the user, merchant, store, owner membership, and audit event together" do
    result = described_class.call(**attributes)

    expect(result.membership.role).to eq("owner")
    expect(result.store.handle).to eq("demo-store")
    expect(result.user.password_digest).to be_present
    event = AuditEvent.last
    expect(event.action).to eq("account.registered")
    expect(event.metadata.keys).not_to include("password", "password_digest")
    expect(event.metadata.to_json).not_to include(password)
  end

  it "rolls back the user and merchant when the handle is invalid" do
    expect do
      described_class.call(**attributes(handle: "Bad Handle"))
    end.to raise_error(ActiveRecord::RecordInvalid)

    expect(User.count).to eq(0)
    expect(Merchant.count).to eq(0)
    expect(Store.count).to eq(0)
    expect(Membership.count).to eq(0)
    expect(AuditEvent.count).to eq(0)
  end

  it "refuses audit metadata that could hold a secret" do
    result = described_class.call(**attributes(handle: "secret-store"))

    expect do
      EventRecorder.call(store: result.store, actor: result.user, action: "store.updated", metadata: { "password" => password })
    end.to raise_error(ArgumentError)
  end
end
