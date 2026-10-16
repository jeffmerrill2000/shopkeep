# ADR 0004: Server-side cookie sessions

## Status

Accepted and implemented in Milestone 2.

## Decision

Authentication uses the Rails `has_secure_password` mechanism and a server-side `sessions` row. The browser receives an HttpOnly, SameSite=Lax session cookie. The cookie is Secure in production. Mutating requests send the Rails CSRF token in `X-CSRF-Token`.

The frontend and API are a first-party pair (Vite proxy in development, one site in production). A bearer token in `localStorage` is rejected because it is exposed to XSS and does not match the CSRF model.

A tenant or store id sent by the browser is never proof of authorization. See ADR 0005.

## Consequences

- The API process stays stateless aside from the session lookup. Sticky sessions are not required.
- CORS allows credentialed requests only from an explicit origin list.
- Password reset email is not part of Milestone 1 or 2.
