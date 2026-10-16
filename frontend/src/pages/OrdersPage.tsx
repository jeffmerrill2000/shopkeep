import { useEffect, useState } from "react";
import { Link, useParams } from "react-router";
import { errorText } from "../api/client";
import { commerceApi, type Order } from "../api/commerce";
import { formatCents } from "../money";
import { StoreGate } from "./StoreFrame";

export default function OrdersPage() {
  return (
    <StoreGate>
      {(store) => <OrderList storeId={store.id} />}
    </StoreGate>
  );
}

function OrderList({ storeId }: { storeId: number }) {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    commerceApi.orders(storeId).then((body) => {
      if (!active) return;
      setOrders(body.orders);
      setLoaded(true);
    }).catch((caught: unknown) => {
      if (active) setError(errorText(caught));
    });
    return () => {
      active = false;
    };
  }, [storeId]);

  return (
    <section className="mt-8">
      <h2 className="font-medium text-stone-900">Orders</h2>
      {error ? <p className="mt-3 text-sm text-red-700" role="alert">{error}</p> : null}
      {loaded && orders.length === 0 ? <p className="mt-3 text-sm text-stone-700">No orders yet.</p> : null}
      <ul className="mt-3 divide-y divide-stone-200 rounded-lg border border-stone-200 bg-white">
        {orders.map((order) => (
          <li key={order.id}>
            <Link className="flex justify-between px-4 py-3 text-sm hover:bg-stone-50" to={`/stores/${storeId}/orders/${order.id}`}>
              <span>{order.number} · {order.email}</span>
              <span>{formatCents(order.total_cents)} · {order.fulfillment_status}</span>
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}

export function OrderDetailPage() {
  return (
    <StoreGate>
      {(store) => <OrderDetail storeId={store.id} canEdit={store.role === "owner" || store.role === "admin"} />}
    </StoreGate>
  );
}

function OrderDetail({ storeId, canEdit }: { storeId: number; canEdit: boolean }) {
  const params = useParams();
  const [order, setOrder] = useState<Order | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [tracking, setTracking] = useState("");

  useEffect(() => {
    let active = true;
    commerceApi.order(storeId, Number(params.orderId)).then((body) => {
      if (active) setOrder(body.order);
    }).catch((caught: unknown) => {
      if (active) setError(errorText(caught));
    });
    return () => {
      active = false;
    };
  }, [storeId, params.orderId]);

  const next = order?.fulfillment_status === "unfulfilled" ? "shipped" : order?.fulfillment_status === "shipped" ? "delivered" : null;

  return (
    <section className="mt-8">
      <h2 className="font-medium text-stone-900">Order {order?.number}</h2>
      {error ? <p className="mt-3 text-sm text-red-700" role="alert">{error}</p> : null}
      {order ? (
        <>
          <p className="mt-2 text-sm text-stone-600">{order.customer_name} · {order.email} · {order.payment_status} · {order.fulfillment_status}</p>
          <ul className="mt-3 space-y-1 text-sm text-stone-700">
            {order.lines.map((line) => (
              <li key={line.id}>{line.title} · {line.quantity} · {formatCents(line.line_total_cents)}</li>
            ))}
          </ul>
          <p className="mt-3 text-sm">Total {formatCents(order.total_cents)} · simulated payment</p>
          {canEdit && next ? (
            <form className="mt-4 flex flex-wrap items-end gap-3" onSubmit={(event) => {
              event.preventDefault();
              void commerceApi.fulfill(storeId, order.id, { status: next, tracking_number: tracking }).then((body) => {
                setOrder(body.order);
                setError(null);
              }).catch((caught: unknown) => setError(errorText(caught)));
            }}>
              <label className="text-sm" htmlFor="tracking">Tracking
                <input id="tracking" className="mt-1 block rounded-md border border-stone-300 px-3 py-2" value={tracking} onChange={(event) => setTracking(event.target.value)} />
              </label>
              <button type="submit" className="rounded-md bg-stone-900 px-3 py-2 text-sm font-medium text-white">Mark {next}</button>
            </form>
          ) : null}
        </>
      ) : null}
    </section>
  );
}
