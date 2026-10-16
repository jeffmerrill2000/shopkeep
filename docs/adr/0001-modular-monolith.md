# ADR 0001: Modular Rails monolith and a separate React app

## Status

Accepted (Milestone 1)

## Decision

ShopKeep is one Rails API application with domain namespaces under `backend/app/domains`, plus a separate Vite React TypeScript app in `frontend/`. Business rules live in domain service objects. Controllers stay thin. React does not own pricing, inventory, authorization, or other business rules.

Domains may call only the dependencies listed in `docs/modules.md`. Cross-domain work goes through a service, not another domain's tables.

## Consequences

- One deployable API and one worker process in Phase 1.
- Packwerk is not introduced until a boundary is actually violated. The written dependency rules are the constraint until then.
- A later extraction of a domain is possible because tables are store-scoped and services are the entry points. That extraction is not a Phase 1 goal.
