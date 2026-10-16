# Module boundaries

ShopKeep is one Rails process. Each module is a namespace under `backend/app/domains`. A module owns its models and the services that change them. Another module does not query those tables.

An arrow means "may call".

```
Identity
  ↑
Tenancy
  ↑
Audit ───────────── (actor and store ids only)

Tenancy + Audit
  ↑
Catalog, Pricing, Inventory, Customers, Cart, Checkout,
Orders, Payments, Fulfillment, Store configuration, Reports, Notifications

Jobs → the service of the module that owns the work
React → typed HTTP client → controllers → one service
```

## Modules

| Module | Responsibility | Depends on | Milestone |
| --- | --- | --- | --- |
| Identity | Users, passwords, sessions, registration | none | 2 |
| Tenancy | Merchants, stores, memberships, roles | Identity | 2 |
| Audit | Append-only record of sensitive administrative actions | Identity, Tenancy | 2 (write path) |
| Jobs | Active Job wrappers and Sidekiq execution | the service it calls | 1 (shell) |
| Catalog | Products, variants, images, collections | Tenancy, Audit | 3 |
| Pricing | Prices and discounts. Integer minor units only | Tenancy, Catalog | 3 and 5 |
| Inventory | On-hand quantities and stock movements | Tenancy, Catalog, Audit | 3 |
| Customers | Customer records and addresses | Tenancy | 6 |
| Cart | Storefront carts and line selections | Catalog, Pricing | 4 |
| Checkout | Price, tax, shipping, inventory, and order creation in one transaction | Cart, Pricing, Inventory, Orders, Payments | 5 |
| Orders | Orders and immutable line snapshots | Tenancy, Catalog | 5 |
| Payments | Simulated payment states. No card data | Orders | 5 |
| Fulfillment | Shipping status transitions | Orders | 6 |
| Store configuration | Currency, tax, and shipping settings | Tenancy | 5 and 6 |
| Reports | Store-scoped sales summaries | Orders | 6 |
| Notifications | Email or other messages triggered by jobs | the event's module | later |

Controllers may depend on the module they expose. The React application has no dependency on Rails models.

Zeitwerk collapses `app/domains/identity`, `tenancy`, `audit`, `catalog`, `inventory`, `pricing`, `cart`, `customers`, `orders`, `checkout`, `fulfillment`, and `reports`. Model and service constants such as `Product`, `Checkout`, and `SalesSummary` are top-level. `Health::Check` stays namespaced. Registration is a tenancy service because it creates the merchant, store, and owner membership and calls identity for the user.

Notifications stay unimplemented. Do not add a placeholder model for them.
