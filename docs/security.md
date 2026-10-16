# Security notes (Phase 1)

Merchant routes authenticate with a server-side session and scope every store through that user's membership. The public storefront is unauthenticated and still CSRF-protected on writes. Guest order access tokens are returned once at checkout and are not copied into audit metadata or outbox payloads.

## In place

- Secrets stay in `.env`, which is gitignored. `.env.example` has local-only placeholders.
- `config/master.key` is gitignored. A generated development key may exist on disk and must not be committed.
- API errors use `{ "error": { "code", "message", "details" } }`. Production must not return stack traces.
- Passwords, tokens, session values, and CSRF parameters are filtered from logs.
- Sessions use `has_secure_password`, an HttpOnly SameSite=Lax cookie, and `X-CSRF-Token` on mutating requests. The cookie is marked Secure when `Rails.env.production?`.
- CORS allows credentialed requests only from `CORS_ORIGINS` (default `http://localhost:5173`) and only for `/api/*`.
- Pundit checks the membership role after the store is loaded through the current user. A missing membership is 404. A member with the wrong role is 403.
- rack-attack allows 5 login or registration posts per IP per minute outside development. Development allows 30 so the local browser suite can sign in from one machine. The test suite uses a memory store and leaves the throttle disabled except in the rate-limit spec, which still expects the 5-attempt limit.
- Audit metadata rejects keys that look like passwords, digests, sessions, cookies, CSRF values, or tokens. Serializers omit `password_digest`.
- The demo seed in `backend/db/seeds.rb` raises in production.
- Product image reads resolve a storage key that must stay inside that store's directory, then return the bytes. Checkout does not store card data. Payment rows are marked simulated.
- CI runs `bundler-audit`, Brakeman, and `npm audit --audit-level=high`. A finding is either fixed or written here with a reason.

## Limitations that remain

- The health endpoint is public by design.
- rack-attack is process-local. It is not an edge or multi-instance limit.
- There is no WAF, MFA, or password-reset email.
- Development uses HTTP on localhost. The Secure cookie flag is set only when the Rails environment is production, and that path is not exercised locally.
- Adding a member by email tells the store owner whether that email already has an account.
- Dependency scans report known advisories only.
- The axe run covers the screens listed above. It does not certify the whole app.
- No payment data is collected.

## Scanner results

Run on 2026-10-15 against the Milestone 7 tree:

- `bundle exec brakeman -q -w2 --no-pager`: 0 warnings (Brakeman 8.1.0, Rails 8.1.4).
- `bundle exec bundler-audit check`: no vulnerabilities (ruby-advisory-db last updated 2026-10-10, 1263 advisories).
- `npm audit --audit-level=high` in `frontend`: 0 vulnerabilities.
- Playwright axe (`@axe-core/playwright`) reported no serious or critical violations on login, registration, the demo storefront, product, cart, empty checkout, an unknown store, and the merchant home, at desktop and a phone-sized viewport. That is not a complete manual WCAG audit.

These results are for this checkout on that date. Re-run the commands after dependency changes. GitHub Actions runs the same checks on push; this repository had no remote when Milestone 2 was verified, so CI was not executed in the cloud.
