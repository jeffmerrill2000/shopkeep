import { api, loadCsrf } from "./client";

export type Variant = {
  id: number;
  product_id: number;
  title: string;
  sku: string;
  price_cents: number;
  status: string;
  on_hand: number | null;
};

export type ProductImage = {
  id: number;
  product_id: number;
  alt_text: string | null;
  content_type: string;
};

export type Product = {
  id: number;
  store_id: number;
  title: string;
  handle: string;
  description: string;
  status: string;
  variants?: Variant[];
  images?: ProductImage[];
};

export type InventoryItem = {
  id: number;
  variant_id: number;
  sku: string;
  product_title: string;
  on_hand: number;
};

export type OrderLine = {
  id: number;
  sku: string;
  title: string;
  quantity: number;
  unit_price_cents: number;
  line_total_cents: number;
};

export type Order = {
  id: number;
  number: string;
  email: string;
  customer_name: string;
  subtotal_cents: number;
  discount_cents: number;
  shipping_cents: number;
  tax_cents: number;
  total_cents: number;
  currency: string;
  discount_code: string | null;
  payment_status: string;
  fulfillment_status: string;
  simulated_payment: boolean;
  lines: OrderLine[];
  access_token?: string;
};

export type Customer = {
  id: number;
  email: string;
  name: string;
  order_count: number;
};

export type DiscountCode = {
  id: number;
  code: string;
  kind: string;
  percent_bps: number | null;
  amount_cents: number | null;
  status: string;
};

export type ShippingRate = { id: number; name: string; price_cents: number; status: string };
export type TaxRate = { id: number; name: string; rate_bps: number; status: string };

export type CartLine = {
  id: number;
  variant_id: number;
  sku: string;
  title: string;
  quantity: number;
  unit_price_cents: number;
  line_total_cents: number;
  for_sale: boolean;
};

export type Cart = { id: number | null; lines: CartLine[] };

export type PublicStore = {
  store: { name: string; handle: string; currency: string };
  products: Product[];
  shipping_rates: ShippingRate[];
  tax_rates: TaxRate[];
};

export type SalesSummary = {
  order_count: number;
  paid_total_cents: number;
  units_sold: number;
};

const storePath = (storeId: number) => `/api/v1/stores/${storeId}`;

export const commerceApi = {
  products: (storeId: number) => api<{ products: Product[] }>(`${storePath(storeId)}/products`),
  createProduct: (storeId: number, body: Record<string, unknown>) =>
    api<{ product: Product }>(`${storePath(storeId)}/products`, { method: "POST", body }),
  archiveProduct: (storeId: number, productId: number) =>
    api<{ product: Product }>(`${storePath(storeId)}/products/${productId}/archive`, { method: "POST", body: {} }),
  updateVariant: (storeId: number, productId: number, variantId: number, priceCents: number) =>
    api<{ variant: Variant }>(`${storePath(storeId)}/products/${productId}/variants/${variantId}`, {
      method: "PATCH",
      body: { price_cents: priceCents },
    }),
  inventory: (storeId: number) => api<{ inventory_items: InventoryItem[] }>(`${storePath(storeId)}/inventory_items`),
  adjustInventory: (storeId: number, itemId: number, body: { delta: number; reason: string }) =>
    api<{ inventory_item: InventoryItem }>(`${storePath(storeId)}/inventory_items/${itemId}/adjustments`, { method: "POST", body }),
  orders: (storeId: number) => api<{ orders: Order[] }>(`${storePath(storeId)}/orders`),
  order: (storeId: number, orderId: number) => api<{ order: Order }>(`${storePath(storeId)}/orders/${orderId}`),
  fulfill: (storeId: number, orderId: number, body: { status: string; tracking_number?: string }) =>
    api<{ order: Order }>(`${storePath(storeId)}/orders/${orderId}/fulfillment`, { method: "POST", body }),
  customers: (storeId: number) => api<{ customers: Customer[] }>(`${storePath(storeId)}/customers`),
  customer: (storeId: number, customerId: number) =>
    api<{ customer: Customer; orders: Order[] }>(`${storePath(storeId)}/customers/${customerId}`),
  discounts: (storeId: number) => api<{ discount_codes: DiscountCode[] }>(`${storePath(storeId)}/discount_codes`),
  summary: (storeId: number) => api<{ sales_summary: SalesSummary }>(`${storePath(storeId)}/sales_summary`),
  shippingRates: (storeId: number) => api<{ shipping_rates: ShippingRate[] }>(`${storePath(storeId)}/shipping_rates`),
  createShippingRate: (storeId: number, body: { name: string; price_cents: number }) =>
    api<{ shipping_rate: ShippingRate }>(`${storePath(storeId)}/shipping_rates`, { method: "POST", body }),
  taxRates: (storeId: number) => api<{ tax_rates: TaxRate[] }>(`${storePath(storeId)}/tax_rates`),
  createTaxRate: (storeId: number, body: { name: string; rate_bps: number }) =>
    api<{ tax_rate: TaxRate }>(`${storePath(storeId)}/tax_rates`, { method: "POST", body }),
  createDiscount: (storeId: number, body: { code: string; kind: string; percent_bps?: number; amount_cents?: number }) =>
    api(`${storePath(storeId)}/discount_codes`, { method: "POST", body }),
  storefront: (handle: string) => api<PublicStore>(`/api/v1/storefront/${handle}`),
  storefrontProduct: (handle: string, productHandle: string) =>
    api<{ product: Product }>(`/api/v1/storefront/${handle}/products/${productHandle}`),
  cart: (handle: string) => api<{ cart: Cart }>(`/api/v1/storefront/${handle}/cart`),
  addLine: (handle: string, body: { variant_id: number; quantity: number }) =>
    api<{ cart: Cart }>(`/api/v1/storefront/${handle}/cart/lines`, { method: "POST", body }),
  updateLine: (handle: string, lineId: number, quantity: number) =>
    api<{ cart: Cart }>(`/api/v1/storefront/${handle}/cart/lines/${lineId}`, { method: "PATCH", body: { quantity } }),
  checkout: (handle: string, idempotencyKey: string, body: Record<string, unknown>) =>
    api<{ order: Order }>(`/api/v1/storefront/${handle}/checkout`, {
      method: "POST",
      body,
      headers: { "Idempotency-Key": idempotencyKey },
    }),
  publicOrder: (handle: string, number: string, accessToken: string) =>
    api<{ order: Order }>(`/api/v1/storefront/${handle}/orders/${number}?access_token=${encodeURIComponent(accessToken)}`),
};

export async function uploadProductImage(storeId: number, productId: number, file: File, altText: string): Promise<void> {
  const token = await loadCsrf();
  const body = new FormData();
  body.set("file", file);
  body.set("alt_text", altText);
  const response = await fetch(`/api/v1/stores/${storeId}/products/${productId}/images`, {
    method: "POST",
    credentials: "include",
    headers: { Accept: "application/json", "X-CSRF-Token": token },
    body,
  });
  if (!response.ok) {
    const payload: unknown = await response.json().catch(() => null);
    const message = isMessage(payload) ? payload.error.message : "The image could not be uploaded.";
    throw new Error(message);
  }
}

function isMessage(payload: unknown): payload is { error: { message: string } } {
  return typeof payload === "object" && payload !== null && "error" in payload;
}
