# ADR 0008: Version matrix

## Status

Accepted (Milestone 1). Patch versions are locked by `backend/.ruby-version`, `backend/Gemfile.lock`, and `frontend/package-lock.json` once those files exist.

## Decision

Recorded on 2026-10-15 from the development machine and current stable releases.

| Component | Pin | Reason |
| --- | --- | --- |
| Ruby | 4.0.7 | Current stable MRI. Rails 8.1 requires Ruby >= 3.2. System Ruby on this Mac is 2.6.10 and is not used |
| Ruby fallback | 3.4.11 | Only if 4.0.7 fails to build or a required native gem fails. Document the failure first |
| Rails | 8.1.4 | Security support through 2027-10-10. Bugfix support ended 2026-10-10 |
| MySQL | 8.4 LTS (`mysql:8.4`) | LTS. 8.0 is end of life. 9.7 is deferred for managed-database compatibility |
| Adapter | trilogy | Ships with Rails. No host MySQL client |
| Redis | 8.4 (`redis:8.4`) | Required cache and Sidekiq broker. Redis 8 is source-available (RSALv2/SSPL); acceptable for local Docker |
| Sidekiq | 8.1.7 OSS | Required. Not Solid Queue. Not Sidekiq Pro |
| Node.js | 26.10.0 | Already installed via Homebrew. Becomes Active LTS on 2026-10-28 |
| npm | 11.19.1 | Bundled with that Node. pnpm and Yarn are not introduced |
| React | 19.3.1 | Current supported major |
| React Router | 8.4.0 | Requires React 19.2+ and Node 22.22+ |
| Vite | 8.3.4 | Current stable. Vite+ is a different toolchain and is not used |
| TypeScript | 6.0.3 | Current stable at scaffold. `strict` and `noUncheckedIndexedAccess` are on |
| Tailwind CSS | 4.3.3 | Styling without a component kit |
| Vitest | 5.0.5 | Component tests |
| ESLint | 10.12.0 | Frontend lint. The Vite template also ships oxlint; ESLint is the check CI runs |
| Bundler | 4.0.23 | Installed with Ruby 4.0.7 |
| MySQL image | 8.4.11 | `mysql --version` inside the running container |
| Redis image | 8.4.7 | `redis-server --version` inside the running container |
| RSpec | rspec-rails 8.0.x | Rails 8.1 |
| OpenAPI | rswag 2.17 and openapi-typescript 7.13.0 | Request specs are the source of the document. Ruby 4 does not ship `ostruct`, so the Gemfile adds it for rswag-ui. openapi-typescript 7.13.0 declares a TypeScript 5 peer; it is installed with the existing TypeScript 6.0.3 toolchain and checked by `tsc` |
| Authorization | Pundit | From Milestone 2 |

Rails 8 generators for Solid Queue, Solid Cache, Solid Cable, Kamal, and Thruster are skipped. See ADR 0003.

## Linker compatibility on this Mac

`xcrun --show-sdk-path` returns `MacOSX27.0.sdk`. That SDK's `.tbd` stubs list `arm64e.x1-macos`. The installed linker (`ld-1267`, Apple clang 21.0.0) reports `unknown architecture` and refuses to link, including a trivial C program. Ruby 4.0.7 itself runs. Native gem extensions do not, until `SDKROOT` points at `MacOSX26.5.sdk`, which is installed beside it and links successfully.

`.mise.toml` sets that `SDKROOT` for this repository. This is not a change of Ruby, Rails, or database. If the Command Line Tools linker is later updated to understand `arm64e.x1`, the pin can be removed.

## Consequences

A failed install does not justify a silent substitution. Update this ADR with the error and the replacement before changing the pin.
