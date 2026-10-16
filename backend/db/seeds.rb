if Rails.env.production?
  raise "Demo seed data is development-only and must not load in production"
end

demo_password = "demodemo12345"
other_password = "otherother1234"

unless User.exists?(email: "demo@shopkeep.test")
  AccountRegistration.call(
    email: "demo@shopkeep.test",
    password: demo_password,
    name: "Demo Owner",
    store_name: "Demo Store",
    handle: "demo",
    currency: "USD"
  )
end

unless User.exists?(email: "other@shopkeep.test")
  AccountRegistration.call(
    email: "other@shopkeep.test",
    password: other_password,
    name: "Other Owner",
    store_name: "Other Store",
    handle: "other-store",
    currency: "USD"
  )
end

demo = Store.find_by!(handle: "demo")
owner = User.find_by!(email: "demo@shopkeep.test")

unless demo.products.exists?(handle: "tee")
  ProductWriter.create(
    store: demo, actor: owner, title: "Demo Tee", handle: "tee", description: "A heavyweight demo tee.",
    sku: "DEMO-TEE-S", price_cents: 2500, on_hand: 500
  )
  product = demo.products.find_by!(handle: "tee")
  VariantWriter.create(product: product, actor: owner, title: "Large", sku: "DEMO-TEE-L", price_cents: 2500, on_hand: 500)
end

unless demo.products.exists?(handle: "mug")
  ProductWriter.create(
    store: demo, actor: owner, title: "Demo Mug", handle: "mug", description: "A ceramic demo mug.",
    sku: "DEMO-MUG", price_cents: 1500, on_hand: 500
  )
end

unless demo.shipping_rates.exists?(name: "Standard")
  ShippingRate.create!(store: demo, name: "Standard", price_cents: 500, status: "active")
end

unless demo.tax_rates.exists?(name: "Local tax")
  TaxRate.create!(store: demo, name: "Local tax", rate_bps: 800, status: "active")
end

unless demo.discount_codes.exists?(code: "SAVE10")
  DiscountCode.create!(store: demo, code: "SAVE10", kind: "percent", percent_bps: 1000, status: "active")
end
