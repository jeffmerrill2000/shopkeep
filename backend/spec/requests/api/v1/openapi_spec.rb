require "swagger_helper"

RSpec.describe "OpenAPI v1", openapi_spec: "v1/swagger.yaml" do
  let(:password) { IdentityHelpers::PASSWORD }

  path "/api/v1/health" do
    get "Service health" do
      tags "Operations"
      produces "application/json"
      response "200", "dependencies are reachable" do
        run_test!
      end
    end
  end

  path "/api/v1/csrf" do
    get "CSRF token" do
      tags "Identity"
      produces "application/json"
      response "200", "token for the session cookie" do
        schema type: :object, required: %w[csrf_token], properties: { csrf_token: { type: :string } }
        run_test!
      end
    end
  end

  path "/api/v1/registration" do
    post "Register an owner, merchant, and store" do
      tags "Identity"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: %w[email password name store_name handle],
        properties: {
          email: { type: :string },
          password: { type: :string },
          name: { type: :string },
          store_name: { type: :string },
          handle: { type: :string },
          currency: { type: :string }
        }
      }

      response "201", "registered" do
        let(:body) do
          { email: "openapi@shopkeep.test", password: password, name: "Open", store_name: "Open Store", handle: "open-store" }
        end
        schema type: :object, required: %w[user store], properties: {
          user: { "$ref" => "#/components/schemas/User" },
          store: { "$ref" => "#/components/schemas/Store" }
        }
        run_test!
      end

      response "422", "invalid" do
        let(:body) { { email: "bad@shopkeep.test", password: "short", name: "Bad", store_name: "Bad", handle: "bad" } }
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end

  path "/api/v1/session" do
    post "Sign in" do
      tags "Identity"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: %w[email password],
        properties: { email: { type: :string }, password: { type: :string } }
      }

      response "200", "signed in" do
        let!(:account) { register_account(email: "session@shopkeep.test", handle: "session-store") }
        let(:body) { { email: account.user.email, password: password } }
        schema type: :object, required: %w[user stores], properties: {
          user: { "$ref" => "#/components/schemas/User" },
          stores: { type: :array, items: { "$ref" => "#/components/schemas/Store" } }
        }
        run_test!
      end

      response "401", "unknown credentials" do
        let(:body) { { email: "missing@shopkeep.test", password: password } }
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end

    delete "Sign out" do
      tags "Identity"
      response "204", "signed out" do
        before { sign_in_as(register_account(email: "signout@shopkeep.test", handle: "signout-store").user) }
        run_test!
      end

      response "401", "signed out already" do
        run_test!
      end
    end
  end

  path "/api/v1/me" do
    get "Current user and stores" do
      tags "Identity"
      produces "application/json"
      response "200", "current session" do
        before { sign_in_as(register_account(email: "me@shopkeep.test", handle: "me-store").user) }
        schema type: :object, required: %w[user stores], properties: {
          user: { "$ref" => "#/components/schemas/User" },
          stores: { type: :array, items: { "$ref" => "#/components/schemas/Store" } }
        }
        run_test!
      end

      response "401", "no session" do
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end

  path "/api/v1/stores" do
    get "List the signed-in user's stores" do
      tags "Stores"
      produces "application/json"
      response "200", "membership stores" do
        before { sign_in_as(register_account(email: "list@shopkeep.test", handle: "list-store").user) }
        schema type: :object, properties: { stores: { type: :array, items: { "$ref" => "#/components/schemas/Store" } } }
        run_test!
      end
    end

    post "Create a store on an owned merchant" do
      tags "Stores"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: %w[merchant_id name handle],
        properties: {
          merchant_id: { type: :integer },
          name: { type: :string },
          handle: { type: :string },
          currency: { type: :string }
        }
      }
      response "201", "store created" do
        let(:account) { register_account(email: "create@shopkeep.test", handle: "create-store") }
        let(:body) { { merchant_id: account.merchant.id, name: "Second", handle: "create-second" } }
        before { sign_in_as(account.user) }
        schema type: :object, properties: { store: { "$ref" => "#/components/schemas/Store" } }
        run_test!
      end
    end
  end

  path "/api/v1/stores/{id}" do
    get "Show a store the user belongs to" do
      tags "Stores"
      produces "application/json"
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      response "200", "store" do
        let(:account) { register_account(email: "show@shopkeep.test", handle: "show-store") }
        let(:id) { account.store.id }
        before { sign_in_as(account.user) }
        schema type: :object, properties: { store: { "$ref" => "#/components/schemas/Store" } }
        run_test!
      end

      response "404", "not a member" do
        let(:account) { register_account(email: "hidden@shopkeep.test", handle: "hidden-store") }
        let(:id) { account.store.id }
        before { sign_in_as(register_account(email: "outsider@shopkeep.test", handle: "outsider-store").user) }
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end

    patch "Update store settings" do
      tags "Stores"
      consumes "application/json"
      produces "application/json"
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: { name: { type: :string }, currency: { type: :string } }
      }
      response "200", "updated" do
        let(:account) { register_account(email: "patch@shopkeep.test", handle: "patch-store") }
        let(:id) { account.store.id }
        let(:body) { { name: "Patched" } }
        before { sign_in_as(account.user) }
        schema type: :object, properties: { store: { "$ref" => "#/components/schemas/Store" } }
        run_test!
      end

      response "403", "staff cannot update" do
        let(:account) { register_account(email: "staff-store@shopkeep.test", handle: "staff-parent") }
        let(:staff) { User.create!(email: "staff-openapi@shopkeep.test", name: "Staff", password: password) }
        let(:id) { account.store.id }
        let(:body) { { name: "Nope" } }
        before do
          Membership.create!(user: staff, store: account.store, role: "staff")
          sign_in_as(staff)
        end
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/memberships" do
    get "List memberships" do
      tags "Memberships"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      response "200", "members" do
        let(:account) { register_account(email: "members@shopkeep.test", handle: "members-store") }
        let(:store_id) { account.store.id }
        before { sign_in_as(account.user) }
        schema type: :object, properties: { memberships: { type: :array, items: { "$ref" => "#/components/schemas/Membership" } } }
        run_test!
      end
    end

    post "Add an admin or staff member" do
      tags "Memberships"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: %w[email role],
        properties: { email: { type: :string }, role: { type: :string } }
      }
      response "201", "membership created" do
        let(:account) { register_account(email: "adder@shopkeep.test", handle: "adder-store") }
        let(:store_id) { account.store.id }
        let(:body) { { email: "invite@shopkeep.test", role: "staff" } }
        before do
          User.create!(email: "invite@shopkeep.test", name: "Invite", password: password)
          sign_in_as(account.user)
        end
        schema type: :object, properties: { membership: { "$ref" => "#/components/schemas/Membership" } }
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/memberships/{id}" do
    patch "Change a membership role" do
      tags "Memberships"
      consumes "application/json"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      parameter name: :body, in: :body, schema: { type: :object, properties: { role: { type: :string } } }
      response "200", "role changed" do
        let(:account) { register_account(email: "role@shopkeep.test", handle: "role-store") }
        let(:member) { User.create!(email: "role-member@shopkeep.test", name: "Member", password: password) }
        let(:store_id) { account.store.id }
        let(:id) { MembershipManager.add(store: account.store, actor: account.user, email: member.email, role: "staff").id }
        let(:body) { { role: "admin" } }
        before { sign_in_as(account.user) }
        schema type: :object, properties: { membership: { "$ref" => "#/components/schemas/Membership" } }
        run_test!
      end
    end

    delete "Remove a membership" do
      tags "Memberships"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      parameter name: :id, in: :path, schema: { type: :integer }, required: true
      response "204", "removed" do
        let(:account) { register_account(email: "remove@shopkeep.test", handle: "remove-store") }
        let(:member) { User.create!(email: "remove-member@shopkeep.test", name: "Member", password: password) }
        let(:store_id) { account.store.id }
        let(:id) { MembershipManager.add(store: account.store, actor: account.user, email: member.email, role: "staff").id }
        before { sign_in_as(account.user) }
        run_test!
      end
    end
  end

  path "/api/v1/stores/{store_id}/audit_events" do
    get "List audit events for a store" do
      tags "Audit"
      produces "application/json"
      parameter name: :store_id, in: :path, schema: { type: :integer }, required: true
      response "200", "events" do
        let(:account) { register_account(email: "audit@shopkeep.test", handle: "audit-store") }
        let(:store_id) { account.store.id }
        before { sign_in_as(account.user) }
        schema type: :object, properties: { audit_events: { type: :array, items: { "$ref" => "#/components/schemas/AuditEvent" } } }
        run_test!
      end

      response "404", "not a member" do
        let(:account) { register_account(email: "audit-hidden@shopkeep.test", handle: "audit-hidden") }
        let(:store_id) { account.store.id }
        before { sign_in_as(register_account(email: "audit-other@shopkeep.test", handle: "audit-other").user) }
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end
end
