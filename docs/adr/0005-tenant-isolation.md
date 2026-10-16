# ADR 0005: Store-scoped tenancy

## Status

Accepted and enforced in Milestone 2.

## Decision

A merchant owns one or more stores. A user belongs to a store through a membership with a role (`owner`, `admin`, `staff`). Merchant-owned rows carry `store_id` and a foreign key.

Every protected store route loads the store and the current user's membership on the server. If either is missing, the response is 404. The response is 403 only when the user is a member and the role is insufficient. List endpoints query through the user's memberships, never through an unscoped table scan filtered by a client-supplied tenant header.

## Consequences

- Sequential ids are not a secret. Authorization does not depend on unguessable ids.
- Tests must show that one merchant cannot read, update, or list another merchant's store, memberships, or audit events.
- Background jobs and reports follow the same scope when those features exist.
