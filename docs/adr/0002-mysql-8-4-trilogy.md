# ADR 0002: MySQL 8.4 LTS and the Trilogy adapter

## Status

Accepted (Milestone 1)

## Decision

The transactional database is MySQL 8.4 LTS, run locally as `mysql:8.4`. Rails uses the built-in Trilogy adapter. Character set is `utf8mb4` with `utf8mb4_0900_ai_ci`.

MySQL 8.0 is end of life. MySQL 9.7 is a newer LTS, and it is deferred so Phase 2 can target a widely deployed MySQL 8.4-compatible managed service and keep a plausible Vitess path. Vitess itself is not installed.

## Consequences

- No MySQL client library is required on the Mac.
- If Trilogy cannot connect to MySQL 8.4 on this machine, stop and record the failure before considering `mysql2`. Do not switch silently.
- Schema design keeps `store_id` on tenant tables so a later shard key exists.
