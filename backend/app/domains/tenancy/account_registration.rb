class AccountRegistration
  Result = Data.define(:user, :merchant, :store, :membership)

  def self.call(email:, password:, name:, store_name:, handle:, currency: "USD", ip_address: nil)
    ActiveRecord::Base.transaction do
      user = User.create!(email: email, password: password, name: name)
      merchant = Merchant.create!(name: store_name)
      store = Store.create!(merchant: merchant, name: store_name, handle: handle, currency: currency)
      membership = Membership.create!(user: user, store: store, role: "owner")
      EventRecorder.call(
        store: store,
        actor: user,
        action: "account.registered",
        subject: store,
        metadata: { "handle" => store.handle, "currency" => store.currency.to_s.strip },
        ip_address: ip_address
      )
      Result.new(user: user, merchant: merchant, store: store, membership: membership)
    end
  end
end
