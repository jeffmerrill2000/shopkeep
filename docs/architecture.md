# Architecture

ShopKeep is a modular Rails API and a separate React storefront and admin UI. Phase 1 runs entirely on a Mac. MySQL is the transactional database. Redis holds cache entries and the Sidekiq queue.

```
Browser
  │
  ▼
Vite (127.0.0.1:5173) ── proxy /api ──► Rails API (127.0.0.1:3000)
                                              │
                                              ├── MySQL 8.4 (127.0.0.1:3306)
                                              └── Redis 8.4 (127.0.0.1:6379)
                                                        ▲
                                              Sidekiq worker
```

The container profile runs the same three application processes in Compose and points them at the Compose DNS names `mysql` and `redis`.

## Request path

1. The React app sends a cookie and, on writes, `X-CSRF-Token`.
2. The controller authenticates the session.
3. Store routes resolve `store_id` from the URL and load the current user's membership. No membership is 404.
4. Pundit checks the role. A member without the role is 403.
5. A domain service performs the change inside a transaction when more than one row is involved.
6. A serializer returns the public fields.

That path covers registration, sessions, stores, memberships, audit events, catalog, inventory, orders, and reports. The public storefront resolves a store by handle and does not accept a client store id as authority. Checkout recomputes prices, discounts, shipping, and tax in one transaction, writes order lines, inventory movements, a simulated payment, and outbox rows, then enqueues `OutboxDrainJob`. Sidekiq marks those rows published. It does not send them to a broker.

## What is intentionally absent

Kafka, Vitess, Kubernetes, and AWS are not part of this runtime. See `docs/adr/0007-defer-kafka-vitess-kubernetes.md`.

## Phase 2 shape (not deployed)

The same images should later run as stateless web processes and a separate worker against a managed MySQL-compatible database and a managed Redis. Product images are files under `backend/storage/product_images` in development and would move to S3-compatible storage later. The `outbox_events` table is the bridge to a future event bus. No cloud infrastructure is created in Phase 1.
