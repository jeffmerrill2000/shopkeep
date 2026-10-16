import { useEffect, useState, type FormEvent } from "react";
import { Navigate, useParams } from "react-router";
import { ApiError, errorText, sessionApi, type AuditEvent, type Membership, type Store } from "../api/client";
import { useAuth } from "../auth/AuthProvider";
import { commerceApi, type DiscountCode, type ShippingRate, type TaxRate } from "../api/commerce";
import { integerCents } from "../money";
import StoreFrame from "./StoreFrame";

export default function StorePage() {
  const auth = useAuth();
  const params = useParams();
  const storeId = Number(params.storeId);
  const store = auth.stores.find((item) => item.id === storeId);
  const [memberships, setMemberships] = useState<Membership[]>([]);
  const [events, setEvents] = useState<AuditEvent[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [name, setName] = useState(store?.name ?? "");
  const [currency, setCurrency] = useState(store?.currency ?? "USD");
  const [memberEmail, setMemberEmail] = useState("");
  const [memberRole, setMemberRole] = useState("staff");

  useEffect(() => {
    if (!store) return;
    let active = true;
    Promise.all([sessionApi.memberships(store.id), sessionApi.auditEvents(store.id)])
      .then(([members, audits]) => {
        if (!active) return;
        setMemberships(members.memberships ?? []);
        setEvents(audits.audit_events ?? []);
        setError(null);
      })
      .catch((caught: unknown) => {
        if (active) setError(errorText(caught));
      });
    return () => {
      active = false;
    };
  }, [store]);

  if (!auth.ready) return <p className="px-6 py-10 text-stone-600">Checking your session…</p>;
  if (!auth.user) return <Navigate to="/login" replace />;
  if (!store) return <Navigate to="/stores" replace />;

  const canEdit = store.role === "owner" || store.role === "admin";
  const isOwner = store.role === "owner";

  async function saveStore(event: FormEvent) {
    event.preventDefault();
    try {
      const body = await sessionApi.updateStore(store.id, { name, currency });
      if (body.store) {
        setName(body.store.name);
        setCurrency(body.store.currency);
      }
      await auth.refresh();
      setError(null);
    } catch (caught) {
      setError(errorText(caught));
    }
  }

  async function addMember(event: FormEvent) {
    event.preventDefault();
    try {
      await sessionApi.addMembership(store.id, { email: memberEmail, role: memberRole });
      const members = await sessionApi.memberships(store.id);
      setMemberships(members.memberships ?? []);
      setMemberEmail("");
      setError(null);
    } catch (caught) {
      setError(errorText(caught));
    }
  }

  return (
    <StoreFrame store={store}>
      {error ? <p className="mt-4 text-sm text-red-700" role="alert">{error}</p> : null}

      {canEdit ? (
        <form className="mt-8 space-y-3 rounded-lg border border-stone-200 bg-white p-4" onSubmit={(event) => void saveStore(event)}>
          <h2 className="font-medium text-stone-900">Store settings</h2>
          <label className="block text-sm" htmlFor="store-name">
            Name
            <input id="store-name" className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2" value={name} onChange={(event) => setName(event.target.value)} />
          </label>
          <label className="block text-sm" htmlFor="store-currency">
            Currency
            <input id="store-currency" className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2" value={currency} onChange={(event) => setCurrency(event.target.value)} />
          </label>
          <button type="submit" className="rounded-md bg-stone-900 px-3 py-2 text-sm font-medium text-white">Save</button>
        </form>
      ) : null}

      <section className="mt-8">
        <h2 className="font-medium text-stone-900">People</h2>
        <ul className="mt-3 divide-y divide-stone-200 rounded-lg border border-stone-200 bg-white">
          {memberships.map((membership) => (
            <li key={membership.id} className="flex items-center justify-between px-4 py-3 text-sm">
              <span>{membership.name} · {membership.email}</span>
              <span className="text-stone-500">{membership.role}</span>
            </li>
          ))}
        </ul>
        {isOwner ? (
          <form className="mt-4 flex flex-wrap items-end gap-3" onSubmit={(event) => void addMember(event)}>
            <label className="text-sm" htmlFor="member-email">
              Email
              <input id="member-email" type="email" className="mt-1 block rounded-md border border-stone-300 px-3 py-2" value={memberEmail} onChange={(event) => setMemberEmail(event.target.value)} />
            </label>
            <label className="text-sm" htmlFor="member-role">
              Role
              <select id="member-role" className="mt-1 block rounded-md border border-stone-300 px-3 py-2" value={memberRole} onChange={(event) => setMemberRole(event.target.value)}>
                <option value="staff">staff</option>
                <option value="admin">admin</option>
              </select>
            </label>
            <button type="submit" className="rounded-md bg-stone-900 px-3 py-2 text-sm font-medium text-white">Add</button>
          </form>
        ) : null}
      </section>

      {canEdit ? <CheckoutSettings store={store} onError={setError} /> : null}

      <section className="mt-8">
        <h2 className="font-medium text-stone-900">Recent activity</h2>
        <ul className="mt-3 space-y-2 text-sm text-stone-700">
          {events.map((event) => (
            <li key={event.id}>{event.action} · {event.created_at}</li>
          ))}
        </ul>
      </section>
    </StoreFrame>
  );
}

function CheckoutSettings({ store, onError }: { store: Store; onError: (message: string | null) => void }) {
  const [shipping, setShipping] = useState<ShippingRate[]>([]);
  const [taxes, setTaxes] = useState<TaxRate[]>([]);
  const [discounts, setDiscounts] = useState<DiscountCode[]>([]);

  async function reload() {
    const [shippingBody, taxBody, discountBody] = await Promise.all([
      commerceApi.shippingRates(store.id),
      commerceApi.taxRates(store.id),
      commerceApi.discounts(store.id),
    ]);
    setShipping(shippingBody.shipping_rates);
    setTaxes(taxBody.tax_rates);
    setDiscounts(discountBody.discount_codes);
  }

  useEffect(() => {
    let active = true;
    Promise.all([
      commerceApi.shippingRates(store.id),
      commerceApi.taxRates(store.id),
      commerceApi.discounts(store.id),
    ]).then(([shippingBody, taxBody, discountBody]) => {
      if (!active) return;
      setShipping(shippingBody.shipping_rates);
      setTaxes(taxBody.tax_rates);
      setDiscounts(discountBody.discount_codes);
    }).catch((caught: unknown) => {
      if (active) onError(errorText(caught));
    });
    return () => {
      active = false;
    };
  }, [onError, store.id]);

  async function onSubmit(event: FormEvent<HTMLFormElement>, save: (data: FormData) => Promise<void>) {
    event.preventDefault();
    try {
      await save(new FormData(event.currentTarget));
      event.currentTarget.reset();
      await reload();
      onError(null);
    } catch (caught) {
      onError(caught instanceof ApiError ? errorText(caught) : caught instanceof Error ? caught.message : "The request could not be completed.");
    }
  }

  return (
    <section className="mt-8 space-y-4">
      <h2 className="font-medium text-stone-900">Checkout settings</h2>
      <ul className="space-y-1 text-sm text-stone-700">
        {shipping.map((rate) => <li key={rate.id}>Shipping {rate.name} · {rate.price_cents} cents</li>)}
        {taxes.map((rate) => <li key={rate.id}>Tax {rate.name} · {rate.rate_bps} basis points</li>)}
        {discounts.map((code) => <li key={code.id}>Discount {code.code}</li>)}
      </ul>
      <form className="flex flex-wrap items-end gap-3" onSubmit={(event) => void onSubmit(event, async (data) => {
        await commerceApi.createShippingRate(store.id, { name: String(data.get("name")), price_cents: integerCents(String(data.get("price_cents"))) });
      })}>
        <Field name="name" label="Shipping name" />
        <Field name="price_cents" label="Shipping cents" />
        <button type="submit" className="rounded-md bg-stone-900 px-3 py-2 text-sm font-medium text-white">Add shipping</button>
      </form>
      <form className="flex flex-wrap items-end gap-3" onSubmit={(event) => void onSubmit(event, async (data) => {
        await commerceApi.createTaxRate(store.id, { name: String(data.get("tax_name")), rate_bps: integerCents(String(data.get("rate_bps"))) });
      })}>
        <Field name="tax_name" label="Tax name" />
        <Field name="rate_bps" label="Tax basis points" />
        <button type="submit" className="rounded-md bg-stone-900 px-3 py-2 text-sm font-medium text-white">Add tax</button>
      </form>
      <form className="flex flex-wrap items-end gap-3" onSubmit={(event) => void onSubmit(event, async (data) => {
        await commerceApi.createDiscount(store.id, {
          code: String(data.get("code")),
          kind: "percent",
          percent_bps: integerCents(String(data.get("percent_bps"))),
        });
      })}>
        <Field name="code" label="Discount code" />
        <Field name="percent_bps" label="Percent basis points" />
        <button type="submit" className="rounded-md bg-stone-900 px-3 py-2 text-sm font-medium text-white">Add discount</button>
      </form>
    </section>
  );
}

function Field({ name, label }: { name: string; label: string }) {
  return (
    <label className="text-sm" htmlFor={name}>
      {label}
      <input id={name} name={name} className="mt-1 block rounded-md border border-stone-300 px-3 py-2" required />
    </label>
  );
}

