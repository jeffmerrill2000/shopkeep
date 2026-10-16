# ADR 0006: Money as integer minor units

## Status

Accepted and implemented. Variant prices, shipping prices, discounts, and order totals are `bigint` minor units. Tax rates are integer basis points.

## Decision

Prices, discounts, shipping, and tax are stored as `bigint` minor units (cents for USD) plus an ISO 4217 currency code on the store. Arithmetic uses integers. Float and `double` columns are forbidden for money. Ruby `Float` is forbidden for money math.

## Consequences

- `MoneyCents` rejects floats and decimal strings such as `10.5`. Amount APIs take non-negative integers.
- Checkout ignores any price sent by the client and snapshots `unit_price_cents` on each order line.
- Tax is integer division: taxable cents times `rate_bps`, divided by 10_000. A 3000 cent subtotal, 10 percent discount, 500 cent shipment, and 800 basis-point tax total 3416 cents.
