# ADR 0007: Defer Kafka, Vitess, and Kubernetes

## Status

Accepted (Milestone 1)

## Decision

Phase 1 runs on a Mac with Docker Compose for MySQL and Redis. Kafka, Vitess, and Kubernetes are not installed and not required to boot the app.

Introduce them only when a later milestone records that the trigger is met:

- Kafka, or a managed Kafka-compatible bus: a second deployable service must consume domain events. Until then, important changes are written to a transactional outbox in the same database transaction and delivered by Sidekiq.
- Vitess: measured MySQL write or storage pressure remains after vertical scaling and replicas. Tenant tables already include `store_id` so a shard key exists.
- Kubernetes (for example EKS): more than one deployable service needs independent scaling or rolling deploys that a single container service cannot operate safely.

Phase 2 design, including Terraform, is Milestone 8. No cloud resources are created without a separate approval.

## Consequences

- The application does not import Kafka or Vitess client libraries in Phase 1.
- Configuration stays in environment variables so the same image can later point at a managed MySQL and Redis.
