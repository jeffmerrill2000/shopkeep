Rswag::Api.configure do |config|
  config.openapi_root = Rails.root.join("openapi").to_s
end

Rswag::Ui.configure do |config|
  config.openapi_endpoint "/api-docs/v1/swagger.yaml", "ShopKeep API v1"
end
