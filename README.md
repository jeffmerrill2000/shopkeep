# ShopKeep

ShopKeep is a multi-tenant commerce application for local development. Merchants own stores, catalogs, inventory, and orders. Shoppers use a public storefront, cart, and simulated checkout. This repository contains Phase 1 through Milestone 7: the Rails API, the React app, MySQL, Redis, and Sidekiq. Kafka, Vitess, Kubernetes, and AWS are not part of this phase.

It is an independent application. It does not use Shopify's proprietary systems.

## Prerequisites

Verified on a Mac with Apple silicon (macOS 26) on 2026-10-15.

- Homebrew
- Docker Desktop, with the engine running
- Node.js 26.10.x and npm 11 (this machine: Node v26.10.0, npm 11.19.1)
- mise, for Ruby: `brew install mise libyaml`
- A shell hook so the project Ruby is selected:

```sh
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
exec zsh
```

The Mac system Ruby (`/usr/bin/ruby` 2.6) cannot run this app. `ruby -v` inside this repository must report Ruby 4.0.7.

This Mac's default Xcode SDK is `MacOSX27`, and its linker cannot read that SDK's `arm64e.x1` stubs. `.mise.toml` sets `SDKROOT` to `MacOSX26.5.sdk` so native gems can link. Keep the mise shell hook enabled. Details are in `docs/adr/0008-version-matrix.md`.

## Start MySQL and Redis

From the repository root:

```sh
cp .env.example .env
docker compose up -d
docker compose ps
```

MySQL listens on `127.0.0.1:3306`. Redis listens on `127.0.0.1:6379`. The database user `shopkeep` with password `shopkeep` is a local development credential, not a production secret.

## Start the API, worker, and UI

```sh
cd backend
bin/setup
bin/rails server -p 3000
```

In a second terminal, from `backend`:

```sh
bundle exec sidekiq
```

In a third terminal:

```sh
cd frontend
npm install
npm run dev
```

- API health: http://127.0.0.1:3000/api/v1/health
- API docs (development): http://127.0.0.1:3000/api-docs
- UI: http://127.0.0.1:5173 (proxies `/api` to the Rails port)

`bin/setup` migrates and loads the local demo. To load it on a database that already exists:

```sh
cd backend && bin/rails db:seed
```

Open http://127.0.0.1:5173/login and sign in as `demo@shopkeep.test` with password `demodemo12345`. That account owns the store `demo`. A second merchant, `other@shopkeep.test` with password `otherother1234`, owns `other-store` so tenant isolation can be checked. The demo seed raises in production.

The public storefront is http://127.0.0.1:5173/s/demo. It lists Demo Tee ($25.00, stored as 2500 cents) and Demo Mug ($15.00). Standard shipping is 500 cents. Local tax is 800 basis points (8 percent). The code `SAVE10` takes 10 percent off the merchandise subtotal. Checkout asks for a shipping address and records a simulated payment. It does not collect a card number. The merchant home shows products, inventory, orders, customers, a sales summary, and the same storefront link. Prices are entered as whole cents.

A healthy response looks like:

```json
{"status":"ok","database":"ok","redis":"ok"}
```

## Container workflow

This builds the API, worker, and frontend and runs them beside MySQL and Redis. Daily development should use the native commands above.

```sh
docker compose --profile app up --build
```

The API is still http://127.0.0.1:3000/api/v1/health and the UI is http://127.0.0.1:5173.

The container image needs OpenSSL headers to compile Trilogy (`libssl-dev` in `backend/Dockerfile`). Stop the app profile with `docker compose --profile app stop api worker frontend` when you want ports 3000 and 5173 back for the native processes. MySQL and Redis keep running.

## Checks

```sh
cd backend && bundle exec rspec
cd backend && bundle exec rake rswag:specs:swaggerize
cd frontend && npm run openapi
cd frontend && npx tsc --noEmit
cd frontend && npx eslint .
cd frontend && npm test
cd frontend && npm run test:e2e
```

Playwright reuses the API on port 3000 and the Vite server on port 5173. Install the browser once with `npx playwright install chromium`.

`bin/rails db:drop` destroys the local development database. It does not touch any other Docker project.

## Versions

See `docs/adr/0008-version-matrix.md`.

## Troubleshooting

- `ruby -v` shows 2.6. Open a new shell after the mise hook, and run commands from the repository root or `backend/` so `.ruby-version` applies.
- Port 3306 or 6379 already in use. Stop the other listener or change the host port in `docker-compose.yml` and `MYSQL_PORT` in `.env` together.
- Health returns `database: error`. Wait until `docker compose ps` shows MySQL healthy, then run `bin/rails db:prepare` again.
- Health returns `redis: error`. Confirm `redis://127.0.0.1:6379/0` matches `REDIS_URL`.
- Trilogy or Ruby 4.0.7 fails to install. Stop and update ADR 0008. Do not switch adapters or Ruby versions without recording the error.

## Milestone status

Milestones 1 through 7 run locally. Milestone 7 adds the merchant journey (catalog, inventory, fulfillment, customers, reports, and sign-out), shopper error states, desktop and mobile Playwright projects, and an axe check for serious and critical issues on the login, storefront, cart, checkout, and merchant home screens. Milestone 8 (Terraform, AWS, Kafka, and Vitess) is not started.

There is no git remote yet, so the GitHub Actions workflow has not run in the cloud. The same checks were run locally. See `docs/security.md` for the scanner output.
