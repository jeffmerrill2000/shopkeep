require "rails_helper"

RSpec.describe User do
  it "stores email in lowercase and rejects a short password" do
    user = User.create!(email: "Owner@Shopkeep.test", name: "Owner", password: "passwordpassword")

    expect(user.email).to eq("owner@shopkeep.test")
    expect(User.new(email: "a@shopkeep.test", name: "A", password: "short").valid?).to be(false)
  end
end
