require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("openapi").to_s
  config.openapi_format = :yaml
  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.3",
      info: {
        title: "ShopKeep API",
        version: "v1",
        description: "Mutating requests send the token from GET /api/v1/csrf in the X-CSRF-Token header and include the session cookie."
      },
      servers: [ { url: "http://127.0.0.1:3000" } ],
      components: {
        schemas: {
          User: {
            type: :object,
            required: %w[id email name],
            properties: {
              id: { type: :integer },
              email: { type: :string },
              name: { type: :string }
            }
          },
          Store: {
            type: :object,
            required: %w[id merchant_id name handle currency status role],
            properties: {
              id: { type: :integer },
              merchant_id: { type: :integer },
              name: { type: :string },
              handle: { type: :string },
              currency: { type: :string },
              status: { type: :string },
              role: { type: :string }
            }
          },
          Membership: {
            type: :object,
            required: %w[id user_id email name role],
            properties: {
              id: { type: :integer },
              user_id: { type: :integer },
              email: { type: :string },
              name: { type: :string },
              role: { type: :string }
            }
          },
          AuditEvent: {
            type: :object,
            required: %w[id action metadata created_at],
            properties: {
              id: { type: :integer },
              action: { type: :string },
              actor_id: { type: :integer, nullable: true },
              subject_type: { type: :string, nullable: true },
              subject_id: { type: :integer, nullable: true },
              metadata: { type: :object, additionalProperties: true },
              ip_address: { type: :string, nullable: true },
              created_at: { type: :string }
            }
          },
          Error: {
            type: :object,
            required: %w[error],
            properties: {
              error: {
                type: :object,
                required: %w[code message details],
                properties: {
                  code: { type: :string },
                  message: { type: :string },
                  details: { type: :object, additionalProperties: { type: :array, items: { type: :string } } }
                }
              }
            }
          }
        }
      },
      paths: {}
    }
  }
end
