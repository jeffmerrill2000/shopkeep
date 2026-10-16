# ShopKeep agent instructions

ShopKeep is an original multi-tenant commerce application. It is not Shopify and does not use Shopify's proprietary systems.

## Scope

- Milestones 1 through 7 are the local Phase 1 app. Do not start Milestone 8 unless the user asks.
- Do not deploy AWS, Kubernetes, Kafka, or Vitess, and do not create cloud resources, unless the user explicitly approves that work.
- Do not replace a requested technology with a different one. If Ruby, Rails, MySQL, Redis, Sidekiq, React, Vite, or TypeScript cannot be used as pinned in `docs/adr/0008-version-matrix.md`, stop and record the incompatibility.

## Where code goes

- HTTP adapters live in `backend/app/controllers`. Controllers authenticate, resolve the store, authorize, call one service, and render a serializer.
- Business rules live in `backend/app/domains/<module>`. Keep pricing, inventory, checkout, and authorization out of React components.
- JSON responses use explicit serializers. Do not render an Active Record object directly.
- React calls the API only through `frontend/src/api`.
- Follow the dependency rules in `docs/modules.md`.

## Tenancy and money

- A store id, merchant id, or tenant header from the browser is not authorization. Load the membership on the server.
- A missing membership is a 404. A membership with the wrong role is a 403.
- Every merchant-owned query is scoped to the authorized store. This includes search, reports, and background jobs.
- Money is integer minor units. Never use `Float`, `double`, or floating-point arithmetic for money.

## Security

- Use `has_secure_password` and the server-side session cookie described in ADR 0004.
- Do not commit `.env`, `master.key`, passwords, tokens, or production credentials.
- Development demo credentials may appear in `db/seeds.rb` and the README. Seeds must refuse to run in production.
- Do not log passwords, session cookies, or card data. The app does not accept card numbers.
- Safe API errors return a code and a message. Production responses do not include stack traces or SQL.

## Tests and claims

- Do not claim that tests, scanners, or a boot sequence passed unless you ran them and read the output.
- After a milestone, run the checks listed for that milestone in the plan: RSpec, a clean migration, TypeScript, lint, and the documented startup path.
- Tenant isolation needs negative request specs, not only policy unit tests.

## Local runtime

- Daily development runs MySQL and Redis with Docker Compose. Rails, Sidekiq, and Vite run on the host.
- `docker compose --profile app` is the container workflow. Keep it working when you change boot or environment variables.
- Use the Ruby installed by mise (`.ruby-version` / `.mise.toml`). Do not use the macOS system Ruby.
