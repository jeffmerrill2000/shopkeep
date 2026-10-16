require "rails_helper"

RSpec.describe "Commerce" do
  def catalog
    account = register_account(email: "merchant@shopkeep.test", handle: "merchant-store", store_name: "Merchant")
    sign_in_as(account.user)
    account
  end

  it "creates a product with an integer price and hides it from another merchant" do
    account = catalog
    post "/api/v1/stores/#{account.store.id}/products",
      params: { title: "Tee", handle: "tee", sku: "TEE-1", price_cents: 2500, on_hand: 4, description: "Soft" },
      as: :json

    expect(response).to have_http_status(:created)
    body = response.parsed_body
    expect(body.dig("product", "variants", 0, "price_cents")).to eq(2500)
    expect(body.dig("product", "variants", 0, "on_hand")).to eq(4)
    expect(response.body).not_to include("password")
    product_id = body.dig("product", "id")

    other = register_account(email: "rival@shopkeep.test", handle: "rival-store")
    sign_in_as(other.user)
    get "/api/v1/stores/#{account.store.id}/products/#{product_id}"
    expect(response).to have_http_status(:not_found)

    get "/api/v1/stores/#{other.store.id}/products"
    expect(response.parsed_body.fetch("products")).to eq([])
  end

  it "rejects decimal money and lets staff read but not create" do
    account = catalog
    post "/api/v1/stores/#{account.store.id}/products",
      params: { title: "Tee", handle: "tee", sku: "TEE-1", price_cents: 10.5, on_hand: 1 },
      as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_amount")
    expect(Product.count).to eq(0)

    post "/api/v1/stores/#{account.store.id}/products",
      params: { title: "Tee", handle: "tee", sku: "TEE-1", price_cents: 2500, on_hand: 2 },
      as: :json
    staff = User.create!(email: "staff@shopkeep.test", name: "Staff", password: IdentityHelpers::PASSWORD)
    Membership.create!(user: staff, store: account.store, role: "staff")
    sign_in_as(staff)
    get "/api/v1/stores/#{account.store.id}/products"
    expect(response).to have_http_status(:ok)
    post "/api/v1/stores/#{account.store.id}/products",
      params: { title: "Other", handle: "other", sku: "TEE-2", price_cents: 100, on_hand: 1 },
      as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it "adjusts stock, fulfills an order, and keeps the sales summary inside the store" do
    account = catalog
    post "/api/v1/stores/#{account.store.id}/products",
      params: { title: "Mug", handle: "mug", sku: "MUG", price_cents: 1500, on_hand: 5 },
      as: :json
    variant_id = response.parsed_body.dig("product", "variants", 0, "id")
    post "/api/v1/stores/#{account.store.id}/shipping_rates", params: { name: "Standard", price_cents: 500 }, as: :json
    shipping_id = response.parsed_body.dig("shipping_rate", "id")
    post "/api/v1/stores/#{account.store.id}/tax_rates", params: { name: "Tax", rate_bps: 800 }, as: :json
    post "/api/v1/stores/#{account.store.id}/discount_codes", params: { code: "save10", kind: "percent", percent_bps: 1000 }, as: :json

    post "/api/v1/storefront/merchant-store/cart/lines", params: { variant_id: variant_id, quantity: 2 }, as: :json
    expect(response).to have_http_status(:created)
    post "/api/v1/storefront/merchant-store/checkout",
      params: {
        email: "buyer@shopkeep.test", name: "Buyer", shipping_rate_id: shipping_id, discount_code: "SAVE10",
        address: { line1: "1 Main", city: "Austin", region: "TX", postal_code: "78701", country: "US" }
      },
      headers: { "Idempotency-Key" => "checkout-1" },
      as: :json

    expect(response).to have_http_status(:created)
    order = response.parsed_body.fetch("order")
    expect(order["subtotal_cents"]).to eq(3000)
    expect(order["discount_cents"]).to eq(300)
    expect(order["shipping_cents"]).to eq(500)
    expect(order["tax_cents"]).to eq(216)
    expect(order["total_cents"]).to eq(3416)
    expect(order["lines"][0]["unit_price_cents"]).to eq(1500)
    expect(order["access_token"]).to be_present
    expect(InventoryItem.find_by(variant_id: variant_id).on_hand).to eq(3)
    expect(OutboxEvent.where(store: account.store).pluck(:event_type)).to contain_exactly(
      "OrderCreated", "PaymentRecorded", "InventoryAdjusted"
    )

    post "/api/v1/storefront/merchant-store/checkout",
      params: {
        email: "buyer@shopkeep.test", name: "Buyer", shipping_rate_id: shipping_id,
        address: { line1: "1 Main", city: "Austin", region: "TX", postal_code: "78701", country: "US" }
      },
      headers: { "Idempotency-Key" => "checkout-1" },
      as: :json
    expect(response.parsed_body.dig("order", "id")).to eq(order["id"])
    expect(Order.count).to eq(1)
    expect(InventoryItem.find_by(variant_id: variant_id).on_hand).to eq(3)

    get "/api/v1/storefront/merchant-store/orders/#{order["number"]}?access_token=#{order["access_token"]}"
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(order["access_token"])

    sign_in_as(account.user)
    get "/api/v1/stores/#{account.store.id}/orders/#{order["id"]}"
    expect(response.body).not_to include("access_token")
    post "/api/v1/stores/#{account.store.id}/orders/#{order["id"]}/fulfillment",
      params: { status: "shipped", tracking_number: "TRACK1" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("order", "fulfillment_status")).to eq("shipped")

    item_id = InventoryItem.find_by!(variant_id: variant_id).id
    post "/api/v1/stores/#{account.store.id}/inventory_items/#{item_id}/adjustments",
      params: { delta: -1, reason: "damage" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("inventory_item", "on_hand")).to eq(2)

    get "/api/v1/stores/#{account.store.id}/sales_summary"
    expect(response.parsed_body["sales_summary"]).to eq(
      "order_count" => 1, "paid_total_cents" => 3416, "units_sold" => 2
    )
    get "/api/v1/stores/#{account.store.id}/customers"
    expect(response.parsed_body.dig("customers", 0, "email")).to eq("buyer@shopkeep.test")

    rival = register_account(email: "summary@shopkeep.test", handle: "summary-store")
    sign_in_as(rival.user)
    get "/api/v1/stores/#{rival.store.id}/sales_summary"
    expect(response.parsed_body.dig("sales_summary", "order_count")).to eq(0)
    get "/api/v1/stores/#{account.store.id}/orders"
    expect(response).to have_http_status(:not_found)
  end

  it "does not oversell the last unit and ignores a client price" do
    account = catalog
    post "/api/v1/stores/#{account.store.id}/products",
      params: { title: "Hat", handle: "hat", sku: "HAT", price_cents: 4000, on_hand: 1 },
      as: :json
    variant_id = response.parsed_body.dig("product", "variants", 0, "id")
    post "/api/v1/stores/#{account.store.id}/shipping_rates", params: { name: "Standard", price_cents: 0 }, as: :json
    shipping_id = response.parsed_body.dig("shipping_rate", "id")

    post "/api/v1/storefront/merchant-store/cart/lines", params: { variant_id: variant_id, quantity: 1, price_cents: 1 }, as: :json
    post "/api/v1/storefront/merchant-store/checkout",
      params: {
        email: "one@shopkeep.test", name: "One", shipping_rate_id: shipping_id, price_cents: 1,
        address: { line1: "1 Main", city: "Austin", region: "TX", postal_code: "78701", country: "US" }
      },
      headers: { "Idempotency-Key" => "one" },
      as: :json
    expect(response.parsed_body.dig("order", "subtotal_cents")).to eq(4000)

    post "/api/v1/storefront/merchant-store/cart/lines", params: { variant_id: variant_id, quantity: 1 }, as: :json
    post "/api/v1/storefront/merchant-store/checkout",
      params: {
        email: "two@shopkeep.test", name: "Two", shipping_rate_id: shipping_id,
        address: { line1: "1 Main", city: "Austin", region: "TX", postal_code: "78701", country: "US" }
      },
      headers: { "Idempotency-Key" => "two" },
      as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("insufficient_stock")
    expect(Order.count).to eq(1)
    expect(InventoryItem.find_by(variant_id: variant_id).on_hand).to eq(0)
  end

  it "hides archived products from the storefront" do
    account = catalog
    post "/api/v1/stores/#{account.store.id}/products",
      params: { title: "Cape", handle: "cape", sku: "CAPE", price_cents: 1000, on_hand: 1 },
      as: :json
    product_id = response.parsed_body.dig("product", "id")
    post "/api/v1/stores/#{account.store.id}/products/#{product_id}/archive"
    get "/api/v1/storefront/merchant-store/products/cape"
    expect(response).to have_http_status(:not_found)
    get "/api/v1/storefront/merchant-store"
    expect(response.parsed_body.fetch("products")).to eq([])
  end
end
