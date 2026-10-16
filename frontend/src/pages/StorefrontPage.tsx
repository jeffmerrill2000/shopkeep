import { useEffect, useState, type FormEvent, type ReactNode } from "react";
import { Link, useNavigate, useParams } from "react-router";
import { errorText } from "../api/client";
import { commerceApi, type Cart, type Order, type Product, type PublicStore, type ShippingRate } from "../api/commerce";
import { formatCents } from "../money";

export default function StorefrontPage() {
  const params = useParams();
  const handle = params.handle ?? "";
  const [catalog, setCatalog] = useState<PublicStore | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    commerceApi.storefront(handle).then((body) => {
      if (active) setCatalog(body);
    }).catch((caught: unknown) => {
      if (active) setError(errorText(caught));
    });
    return () => {
      active = false;
    };
  }, [handle]);

  return (
    <StoreShell handle={handle} title={catalog?.store.name ?? "Store"}>
      {error ? <p className="mt-4 text-sm text-red-800" role="alert">{error}</p> : null}
      {(catalog?.products.length ?? 0) === 0 && !error ? <p className="mt-6 text-sm text-stone-700">No products are listed.</p> : null}
      <ul className="mt-6 grid gap-3">
        {(catalog?.products ?? []).map((product) => (
          <li key={product.id} className="rounded-lg border border-stone-200 bg-white p-4">
            <Link className="text-lg font-medium text-stone-900" to={`/s/${handle}/products/${product.handle}`}>{product.title}</Link>
            <p className="mt-1 text-sm text-stone-600">{product.description}</p>
            <p className="mt-2 text-sm">{formatCents(product.variants?.[0]?.price_cents ?? 0)}</p>
          </li>
        ))}
      </ul>
    </StoreShell>
  );
}

export function StorefrontProductPage() {
  const params = useParams();
  const handle = params.handle ?? "";
  const [product, setProduct] = useState<Product | null>(null);
  const [variantId, setVariantId] = useState("");
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();

  useEffect(() => {
    let active = true;
    commerceApi.storefrontProduct(handle, params.productHandle ?? "").then((body) => {
      if (!active) return;
      setProduct(body.product);
      setVariantId(String(body.product.variants?.[0]?.id ?? ""));
    }).catch((caught: unknown) => {
      if (active) setError(errorText(caught));
    });
    return () => {
      active = false;
    };
  }, [handle, params.productHandle]);

  async function add(event: FormEvent) {
    event.preventDefault();
    try {
      await commerceApi.addLine(handle, { variant_id: Number(variantId), quantity: 1 });
      await navigate(`/s/${handle}/cart`);
    } catch (caught) {
      setError(errorText(caught));
    }
  }

  return (
    <StoreShell handle={handle} title={product?.title ?? "Product"}>
      {error ? <p className="mt-4 text-sm text-red-700" role="alert">{error}</p> : null}
      {product ? (
        <form className="mt-6 space-y-3" onSubmit={(event) => void add(event)}>
          <p className="text-stone-600">{product.description}</p>
          <label className="block text-sm" htmlFor="variant">Variant
            <select id="variant" className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2" value={variantId} onChange={(event) => setVariantId(event.target.value)}>
              {(product.variants ?? []).map((variant) => (
                <option key={variant.id} value={variant.id}>{variant.title} · {formatCents(variant.price_cents)} · {variant.on_hand ?? 0} on hand</option>
              ))}
            </select>
          </label>
          <button type="submit" className="rounded-md bg-stone-900 px-3 py-2 text-sm font-medium text-white">Add to cart</button>
        </form>
      ) : null}
    </StoreShell>
  );
}

export function CartPage() {
  const params = useParams();
  const handle = params.handle ?? "";
  const [cart, setCart] = useState<Cart | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    commerceApi.cart(handle).then((body) => {
      if (active) setCart(body.cart);
    }).catch((caught: unknown) => {
      if (active) setError(errorText(caught));
    });
    return () => {
      active = false;
    };
  }, [handle]);

  return (
    <StoreShell handle={handle} title="Cart">
      {error ? <p className="mt-4 text-sm text-red-700" role="alert">{error}</p> : null}
      {(cart?.lines.length ?? 0) === 0 ? <p className="mt-6 text-sm text-stone-700">Your cart is empty.</p> : null}
      <ul className="mt-6 divide-y divide-stone-200 rounded-lg border border-stone-200 bg-white">
        {(cart?.lines ?? []).map((line) => (
          <li key={line.id} className="flex justify-between px-4 py-3 text-sm">
            <span>{line.title} · {line.quantity}</span>
            <span>{formatCents(line.line_total_cents)}</span>
          </li>
        ))}
      </ul>
      <Link className="mt-4 inline-block rounded-md bg-stone-900 px-3 py-2 text-sm font-medium text-white" to={`/s/${handle}/checkout`}>Checkout</Link>
    </StoreShell>
  );
}

export function CheckoutPage() {
  const params = useParams();
  const handle = params.handle ?? "";
  const navigate = useNavigate();
  const [rates, setRates] = useState<ShippingRate[]>([]);
  const [shippingRateId, setShippingRateId] = useState("");
  const [lineCount, setLineCount] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [discount, setDiscount] = useState("");

  useEffect(() => {
    let active = true;
    Promise.all([commerceApi.storefront(handle), commerceApi.cart(handle)]).then(([body, cartBody]) => {
      if (!active) return;
      setRates(body.shipping_rates);
      setShippingRateId(String(body.shipping_rates[0]?.id ?? ""));
      setLineCount(cartBody.cart.lines.length);
    }).catch((caught: unknown) => {
      if (active) setError(errorText(caught));
    });
    return () => {
      active = false;
    };
  }, [handle]);

  async function place(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    try {
      const body = await commerceApi.checkout(handle, crypto.randomUUID(), {
        email: String(data.get("email")),
        name: String(data.get("customer_name")),
        discount_code: discount,
        shipping_rate_id: Number(shippingRateId),
        address: {
          line1: String(data.get("line1")),
          city: String(data.get("city")),
          region: String(data.get("region")),
          postal_code: String(data.get("postal_code")),
          country: String(data.get("country")),
        },
      });
      const token = body.order.access_token ?? "";
      sessionStorage.setItem(`shopkeep-order-${body.order.number}`, token);
      await navigate(`/s/${handle}/orders/${body.order.number}`);
    } catch (caught) {
      setError(caught instanceof Error && !("status" in caught) ? caught.message : errorText(caught));
    }
  }

  return (
    <StoreShell handle={handle} title="Checkout">
      {error ? <p className="mt-4 text-sm text-red-700" role="alert">{error}</p> : null}
      <p className="mt-3 text-sm text-stone-700">Prices, tax, and shipping are calculated on the server. Payment is simulated and no card number is collected.</p>
      {lineCount === 0 ? (
        <p className="mt-4 text-sm text-stone-800" role="status">Your cart is empty. Add a product before checkout.</p>
      ) : null}
      {lineCount !== null && lineCount > 0 ? (
      <form className="mt-4 grid gap-3" onSubmit={(event) => void place(event)}>
        <Text name="email" label="Email" type="email" />
        <Text name="customer_name" label="Name" />
        <Text name="line1" label="Address" />
        <Text name="city" label="City" />
        <Text name="region" label="Region" />
        <Text name="postal_code" label="Postal code" />
        <Text name="country" label="Country" />
        <label className="text-sm" htmlFor="shipping-rate">Shipping
          <select id="shipping-rate" className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2" value={shippingRateId} onChange={(event) => setShippingRateId(event.target.value)}>
            {rates.map((rate) => <option key={rate.id} value={rate.id}>{rate.name} · {formatCents(rate.price_cents)}</option>)}
          </select>
        </label>
        <label className="text-sm" htmlFor="discount-code">Discount code
          <input id="discount-code" className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2" value={discount} onChange={(event) => setDiscount(event.target.value)} />
        </label>
        <button type="submit" className="w-fit rounded-md bg-stone-900 px-3 py-2 text-sm font-medium text-white">Place order</button>
      </form>
      ) : null}
    </StoreShell>
  );
}

export function ConfirmationPage() {
  const params = useParams();
  const handle = params.handle ?? "";
  const number = params.number ?? "";
  const [order, setOrder] = useState<Order | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const token = sessionStorage.getItem(`shopkeep-order-${number}`);
    if (!token) {
      setError("This confirmation is only available in the browser that placed the order.");
      return;
    }
    let active = true;
    commerceApi.publicOrder(handle, number, token).then((body) => {
      if (active) setOrder(body.order);
    }).catch((caught: unknown) => {
      if (active) setError(errorText(caught));
    });
    return () => {
      active = false;
    };
  }, [handle, number]);

  return (
    <StoreShell handle={handle} title="Order confirmed">
      {error ? <p className="mt-4 text-sm text-red-700" role="alert">{error}</p> : null}
      {order ? (
        <div className="mt-4 text-sm text-stone-700">
          <p>Order {order.number}</p>
          <p>Total {formatCents(order.total_cents)}</p>
          <p>Payment {order.payment_status} (simulated)</p>
        </div>
      ) : null}
    </StoreShell>
  );
}

function StoreShell({ handle, title, children }: { handle: string; title: string; children: ReactNode }) {
  return (
    <main id="main" className="mx-auto min-h-svh max-w-3xl px-4 py-8 sm:px-6 sm:py-10">
      <p className="text-sm font-medium tracking-wide text-stone-600">ShopKeep</p>
      <h1 className="mt-2 text-3xl font-semibold break-words text-stone-900">{title}</h1>
      <nav className="mt-4 flex gap-3 text-sm">
        <Link to={`/s/${handle}`}>Catalog</Link>
        <Link to={`/s/${handle}/cart`}>Cart</Link>
      </nav>
      {children}
    </main>
  );
}

function Text({ name, label, type = "text" }: { name: string; label: string; type?: string }) {
  return (
    <label className="text-sm" htmlFor={name}>
      {label}
      <input id={name} name={name} type={type} required className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2" />
    </label>
  );
}
