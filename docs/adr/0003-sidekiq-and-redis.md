# ADR 0003: Sidekiq and Redis, not Solid Queue

## Status

Accepted (Milestone 1)

## Decision

Background jobs run through Active Job with the Sidekiq adapter (OSS Sidekiq 8.1.x) on Redis 8.4. Rails.cache uses the Redis cache store.

Rails 8 defaults to Solid Queue, Solid Cache, and Solid Cable, which store those workloads in the relational database. ShopKeep does not use them. The product requirements call for Redis and Sidekiq, and Phase 2 expects a managed Redis. Action Cable is not installed because Phase 1 has no websocket feature.

## Consequences

- Local Compose runs Redis. The web process does not execute jobs inline in production-shaped environments.
- Jobs receive record ids, then reload the store on the server. A tenant id inside a job payload is not authorization.
- Checkout writes `outbox_events` in the order transaction. `OutboxDrainJob` marks them published. Until a second service needs those events, Sidekiq is the consumer. Kafka stays deferred (ADR 0007).
