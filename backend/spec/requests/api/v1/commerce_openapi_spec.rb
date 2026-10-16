require "swagger_helper"

RSpec.describe "OpenAPI commerce", openapi_spec: "v1/swagger.yaml" do
  def pixel_upload
    io = Tempfile.new([ "pixel", ".png" ])
    io.binmode
    io.write(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="))
    io.rewind
    Rack::Test::UploadedFile.new(io.path, "image/png")
  end

  def sample_product(store, actor, sku: "SKU-1")
    ProductWriter.create(
      store: store, actor: actor, title: "Tee", handle: "tee", description: "Soft",
      sku: sku, price_cents: 2500, on_hand: 4
    )
  end

  path "/api/v1/stores/{store_id}/products" do
    get "List products" do
      tags "Catalog"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      response "200", "products" do
        let(:account) { register_account(email: "openapi-products@shopkeep.test", handle: "openapi-products") }
        let(:store_id) { account.store.id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end

    post "Create a product and its first variant" do
      tags "Catalog"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true, schema: { type: :object }
      response "201", "created" do
        let(:account) { register_account(email: "openapi-product-new@shopkeep.test", handle: "openapi-product-new") }
        let(:store_id) { account.store.id }
        let(:body) { { title: "Tee", handle: "tee", description: "Soft", sku: "TEE-1", price_cents: 2500, on_hand: 2 } }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/products/{id}" do
    get "Show a product" do
      tags "Catalog"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      response "200", "product" do
        let(:account) { register_account(email: "openapi-product-show@shopkeep.test", handle: "openapi-product-show") }
        let(:store_id) { account.store.id }
        let(:id) { sample_product(account.store, account.user).id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end

    patch "Update a product" do
      tags "Catalog"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, schema: { type: :object }
      response "200", "updated" do
        let(:account) { register_account(email: "openapi-product-patch@shopkeep.test", handle: "openapi-product-patch") }
        let(:store_id) { account.store.id }
        let(:id) { sample_product(account.store, account.user).id }
        let(:body) { { title: "Renamed" } }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/products/{id}/archive" do
    post "Archive a product" do
      tags "Catalog"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      response "200", "archived" do
        let(:account) { register_account(email: "openapi-archive@shopkeep.test", handle: "openapi-archive") }
        let(:store_id) { account.store.id }
        let(:id) { sample_product(account.store, account.user).id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/products/{product_id}/variants" do
    post "Add a variant" do
      tags "Catalog"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :product_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true, schema: { type: :object }
      response "201", "created" do
        let(:account) { register_account(email: "openapi-variant@shopkeep.test", handle: "openapi-variant") }
        let(:store_id) { account.store.id }
        let(:product_id) { sample_product(account.store, account.user).id }
        let(:body) { { title: "Large", sku: "TEE-L", price_cents: 2600, on_hand: 1 } }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/products/{product_id}/variants/{id}" do
    patch "Update a variant" do
      tags "Catalog"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :product_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, schema: { type: :object }
      response "200", "updated" do
        let(:account) { register_account(email: "openapi-variant-patch@shopkeep.test", handle: "openapi-variant-patch") }
        let(:product) { sample_product(account.store, account.user) }
        let(:store_id) { account.store.id }
        let(:product_id) { product.id }
        let(:id) { product.variants.first.id }
        let(:body) { { price_cents: 2700 } }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/products/{product_id}/images" do
    post "Upload a product image" do
      tags "Catalog"
      consumes "multipart/form-data"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :product_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :file, in: :formData, type: :file, required: true
      parameter name: :alt_text, in: :formData, type: :string
      response "201", "stored" do
        let(:account) { register_account(email: "openapi-image@shopkeep.test", handle: "openapi-image") }
        let(:store_id) { account.store.id }
        let(:product_id) { sample_product(account.store, account.user).id }
        let(:file) { pixel_upload }
        let(:alt_text) { "Front" }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/products/{product_id}/images/{id}" do
    get "Download a product image" do
      tags "Catalog"
      produces "image/png"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :product_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      response "200", "file" do
        let(:account) { register_account(email: "openapi-image-get@shopkeep.test", handle: "openapi-image-get") }
        let(:product) { sample_product(account.store, account.user) }
        let(:store_id) { account.store.id }
        let(:product_id) { product.id }
        let(:id) { ImageAttacher.call(product: product, upload: pixel_upload, alt_text: "Front").id }
        before { sign_in_as(account.user) }
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/collections" do
    get "List collections" do
      tags "Catalog"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      response "200", "collections" do
        let(:account) { register_account(email: "openapi-collections@shopkeep.test", handle: "openapi-collections") }
        let(:store_id) { account.store.id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end

    post "Create a collection" do
      tags "Catalog"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true, schema: { type: :object }
      response "201", "created" do
        let(:account) { register_account(email: "openapi-collection-new@shopkeep.test", handle: "openapi-collection-new") }
        let(:store_id) { account.store.id }
        let(:body) { { title: "Summer", handle: "summer" } }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/collections/{id}/products" do
    post "Add a product to a collection" do
      tags "Catalog"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true, schema: { type: :object }
      response "200", "added" do
        let(:account) { register_account(email: "openapi-collection-add@shopkeep.test", handle: "openapi-collection-add") }
        let(:product) { sample_product(account.store, account.user) }
        let(:store_id) { account.store.id }
        let(:id) { CollectionWriter.create(store: account.store, actor: account.user, title: "Summer", handle: "summer").id }
        let(:body) { { product_id: product.id } }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/inventory_items" do
    get "List inventory" do
      tags "Inventory"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      response "200", "items" do
        let(:account) { register_account(email: "openapi-inventory@shopkeep.test", handle: "openapi-inventory") }
        let(:store_id) { account.store.id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/inventory_items/{id}/adjustments" do
    post "Adjust on-hand inventory" do
      tags "Inventory"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true, schema: { type: :object }
      response "200", "adjusted" do
        let(:account) { register_account(email: "openapi-adjust@shopkeep.test", handle: "openapi-adjust") }
        let(:product) { sample_product(account.store, account.user) }
        let(:store_id) { account.store.id }
        let(:id) { product.variants.first.inventory_item.id }
        let(:body) { { delta: 1, reason: "received" } }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/discount_codes" do
    get "List discount codes" do
      tags "Pricing"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      response "200", "codes" do
        let(:account) { register_account(email: "openapi-discounts@shopkeep.test", handle: "openapi-discounts") }
        let(:store_id) { account.store.id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end

    post "Create a discount code" do
      tags "Pricing"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true, schema: { type: :object }
      response "201", "created" do
        let(:account) { register_account(email: "openapi-discount-new@shopkeep.test", handle: "openapi-discount-new") }
        let(:store_id) { account.store.id }
        let(:body) { { code: "SAVE10", kind: "percent", percent_bps: 1000 } }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/shipping_rates" do
    get "List shipping rates" do
      tags "Pricing"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      response "200", "rates" do
        let(:account) { register_account(email: "openapi-shipping@shopkeep.test", handle: "openapi-shipping") }
        let(:store_id) { account.store.id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end

    post "Create a shipping rate" do
      tags "Pricing"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true, schema: { type: :object }
      response "201", "created" do
        let(:account) { register_account(email: "openapi-shipping-new@shopkeep.test", handle: "openapi-shipping-new") }
        let(:store_id) { account.store.id }
        let(:body) { { name: "Standard", price_cents: 500 } }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/tax_rates" do
    get "List tax rates" do
      tags "Pricing"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      response "200", "rates" do
        let(:account) { register_account(email: "openapi-tax@shopkeep.test", handle: "openapi-tax") }
        let(:store_id) { account.store.id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end

    post "Create a tax rate" do
      tags "Pricing"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true, schema: { type: :object }
      response "201", "created" do
        let(:account) { register_account(email: "openapi-tax-new@shopkeep.test", handle: "openapi-tax-new") }
        let(:store_id) { account.store.id }
        let(:body) { { name: "Local", rate_bps: 800 } }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/orders" do
    get "List orders" do
      tags "Orders"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      response "200", "orders" do
        let(:account) { register_account(email: "openapi-orders@shopkeep.test", handle: "openapi-orders") }
        let(:store_id) { account.store.id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/orders/{id}" do
    get "Show an order" do
      tags "Orders"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      response "200", "order" do
        let(:account) { register_account(email: "openapi-order-show@shopkeep.test", handle: "openapi-order-show") }
        let(:store_id) { account.store.id }
        let(:id) { placed_order(account).id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/orders/{id}/fulfillment" do
    post "Advance fulfillment" do
      tags "Orders"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true, schema: { type: :object }
      response "200", "updated" do
        let(:account) { register_account(email: "openapi-fulfill@shopkeep.test", handle: "openapi-fulfill") }
        let(:store_id) { account.store.id }
        let(:id) { placed_order(account).id }
        let(:body) { { status: "shipped", tracking_number: "TRACK" } }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/customers" do
    get "List customers" do
      tags "Customers"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      response "200", "customers" do
        let(:account) { register_account(email: "openapi-customers@shopkeep.test", handle: "openapi-customers") }
        let(:store_id) { account.store.id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/customers/{id}" do
    get "Show a customer" do
      tags "Customers"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      response "200", "customer" do
        let(:account) { register_account(email: "openapi-customer-show@shopkeep.test", handle: "openapi-customer-show") }
        let(:store_id) { account.store.id }
        let(:id) { placed_order(account).customer_id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/sales_summary" do
    get "Sales summary" do
      tags "Reports"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      response "200", "summary" do
        let(:account) { register_account(email: "openapi-summary@shopkeep.test", handle: "openapi-summary") }
        let(:store_id) { account.store.id }
        before { sign_in_as(account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/storefront/{handle}" do
    get "Public storefront" do
      tags "Storefront"
      produces "application/json"
      parameter name: :handle, in: :path, schema: { type: :string }, required: true
      response "200", "catalog" do
        let(:account) { register_account(email: "openapi-front@shopkeep.test", handle: "openapi-front") }
        let(:handle) { account.store.handle }
        before { sample_product(account.store, account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/storefront/{handle}/products" do
    get "Public products" do
      tags "Storefront"
      produces "application/json"
      parameter name: :handle, in: :path, schema: { type: :string }, required: true
      response "200", "products" do
        let(:account) { register_account(email: "openapi-front-products@shopkeep.test", handle: "openapi-front-products") }
        let(:handle) { account.store.handle }
        before { sample_product(account.store, account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/storefront/{handle}/products/{product_handle}" do
    get "Public product" do
      tags "Storefront"
      produces "application/json"
      parameter name: :handle, in: :path, schema: { type: :string }, required: true
      parameter name: :product_handle, in: :path, schema: { type: :string }, required: true
      response "200", "product" do
        let(:account) { register_account(email: "openapi-front-product@shopkeep.test", handle: "openapi-front-product") }
        let(:handle) { account.store.handle }
        let(:product_handle) { "tee" }
        before { sample_product(account.store, account.user) }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/storefront/{handle}/images/{id}" do
    get "Public product image" do
      tags "Storefront"
      produces "image/png"
      parameter name: :handle, in: :path, schema: { type: :string }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      response "200", "file" do
        let(:account) { register_account(email: "openapi-front-image@shopkeep.test", handle: "openapi-front-image") }
        let(:product) { sample_product(account.store, account.user) }
        let(:handle) { account.store.handle }
        let(:id) { ImageAttacher.call(product: product, upload: pixel_upload, alt_text: "Front").id }
        run_test!
      end
    end
  end

  path "/api/v1/storefront/{handle}/cart" do
    get "Public cart" do
      tags "Storefront"
      produces "application/json"
      parameter name: :handle, in: :path, schema: { type: :string }, required: true
      response "200", "cart" do
        let(:account) { register_account(email: "openapi-cart@shopkeep.test", handle: "openapi-cart") }
        let(:handle) { account.store.handle }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/storefront/{handle}/cart/lines" do
    post "Add a cart line" do
      tags "Storefront"
      consumes "application/json"
      produces "application/json"
      parameter name: :handle, in: :path, schema: { type: :string }, required: true
      parameter name: :body, in: :body, required: true, schema: { type: :object }
      response "201", "added" do
        let(:account) { register_account(email: "openapi-cart-add@shopkeep.test", handle: "openapi-cart-add") }
        let(:product) { sample_product(account.store, account.user) }
        let(:handle) { account.store.handle }
        let(:body) { { variant_id: product.variants.first.id, quantity: 1 } }
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/storefront/{handle}/cart/lines/{id}" do
    patch "Update a cart line" do
      tags "Storefront"
      consumes "application/json"
      produces "application/json"
      parameter name: :handle, in: :path, schema: { type: :string }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true, schema: { type: :object }
      response "200", "updated" do
        let(:account) { register_account(email: "openapi-cart-patch@shopkeep.test", handle: "openapi-cart-patch") }
        let(:handle) { account.store.handle }
        let(:id) { CartLine.order(:id).last.id }
        let(:body) { { quantity: 2 } }
        before do
          product = sample_product(account.store, account.user)
          post "/api/v1/storefront/#{account.store.handle}/cart/lines",
            params: { variant_id: product.variants.first.id, quantity: 1 }, as: :json
        end
        schema type: :object
        run_test!
      end
    end

    delete "Remove a cart line" do
      tags "Storefront"
      produces "application/json"
      parameter name: :handle, in: :path, schema: { type: :string }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      response "200", "removed" do
        let(:account) { register_account(email: "openapi-cart-delete@shopkeep.test", handle: "openapi-cart-delete") }
        let(:handle) { account.store.handle }
        let(:id) { CartLine.order(:id).last.id }
        before do
          product = sample_product(account.store, account.user)
          post "/api/v1/storefront/#{account.store.handle}/cart/lines",
            params: { variant_id: product.variants.first.id, quantity: 1 }, as: :json
        end
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/storefront/{handle}/checkout" do
    post "Check out the current cart" do
      tags "Storefront"
      consumes "application/json"
      produces "application/json"
      parameter name: :handle, in: :path, schema: { type: :string }, required: true
      parameter name: "Idempotency-Key", in: :header, schema: { type: :string }, required: true
      parameter name: :body, in: :body, required: true, schema: { type: :object }
      response "201", "order placed" do
        let(:account) { register_account(email: "openapi-checkout@shopkeep.test", handle: "openapi-checkout") }
        let(:handle) { account.store.handle }
        let(:"Idempotency-Key") { "openapi-checkout-key" }
        let(:body) do
          {
            email: "buyer-openapi@shopkeep.test", name: "Buyer", shipping_rate_id: ShippingRate.last.id,
            address: { line1: "1 Main", city: "Austin", region: "TX", postal_code: "78701", country: "US" }
          }
        end
        before do
          product = sample_product(account.store, account.user)
          ShippingRate.create!(store: account.store, name: "Standard", price_cents: 500, status: "active")
          post "/api/v1/storefront/#{account.store.handle}/cart/lines",
            params: { variant_id: product.variants.first.id, quantity: 1 }, as: :json
        end
        schema type: :object
        run_test!
      end
    end
  end

  path "/api/v1/storefront/{handle}/orders/{number}" do
    get "Public order confirmation" do
      tags "Storefront"
      produces "application/json"
      parameter name: :handle, in: :path, schema: { type: :string }, required: true
      parameter name: :number, in: :path, schema: { type: :string }, required: true
      parameter name: :access_token, in: :query, schema: { type: :string }, required: true
      response "200", "order" do
        let(:account) { register_account(email: "openapi-confirmation@shopkeep.test", handle: "openapi-confirmation") }
        let(:order) { placed_order(account) }
        let(:handle) { account.store.handle }
        let(:number) { order.number }
        let(:access_token) { order.access_token }
        schema type: :object
        run_test!
      end
    end
  end

  def placed_order(account)
    product = sample_product(account.store, account.user, sku: "ORDER-SKU")
    rate = ShippingRate.create!(store: account.store, name: "Standard", price_cents: 500, status: "active")
    cart = Cart.create!(store: account.store, token: SecureRandom.hex(8), status: "open")
    CartManager.add(cart: cart, variant: product.variants.first, quantity: 1)
    Checkout.call(
      store: account.store, cart: cart, email: "buyer-placed@shopkeep.test", name: "Buyer",
      address: { "line1" => "1 Main", "city" => "Austin", "region" => "TX", "postal_code" => "78701", "country" => "US" },
      shipping_rate_id: rate.id, discount_code: nil, idempotency_key: "placed-#{account.store.id}"
    )
  end
end
