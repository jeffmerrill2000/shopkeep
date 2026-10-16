import { useEffect, useState } from "react";
import { Link, useParams } from "react-router";
import { errorText } from "../api/client";
import { commerceApi, type Customer, type Order } from "../api/commerce";
import { formatCents } from "../money";
import { StoreGate } from "./StoreFrame";

export default function CustomersPage() {
  return (
    <StoreGate>
      {(store) => <CustomerList storeId={store.id} />}
    </StoreGate>
  );
}

function CustomerList({ storeId }: { storeId: number }) {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    commerceApi.customers(storeId).then((body) => {
      if (!active) return;
      setCustomers(body.customers);
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
      <h2 className="font-medium text-stone-900">Customers</h2>
      {error ? <p className="mt-3 text-sm text-red-700" role="alert">{error}</p> : null}
      {loaded && customers.length === 0 ? <p className="mt-3 text-sm text-stone-700">No customers yet.</p> : null}
      <ul className="mt-3 divide-y divide-stone-200 rounded-lg border border-stone-200 bg-white">
        {customers.map((customer) => (
          <li key={customer.id}>
            <Link className="flex justify-between px-4 py-3 text-sm hover:bg-stone-50" to={`/stores/${storeId}/customers/${customer.id}`}>
              <span>{customer.name} · {customer.email}</span>
              <span>{customer.order_count} orders</span>
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}

export function CustomerDetailPage() {
  return (
    <StoreGate>
      {(store) => <CustomerDetail storeId={store.id} />}
    </StoreGate>
  );
}

function CustomerDetail({ storeId }: { storeId: number }) {
  const params = useParams();
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [orders, setOrders] = useState<Order[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    commerceApi.customer(storeId, Number(params.customerId)).then((body) => {
      if (!active) return;
      setCustomer(body.customer);
      setOrders(body.orders);
    }).catch((caught: unknown) => {
      if (active) setError(errorText(caught));
    });
    return () => {
      active = false;
    };
  }, [storeId, params.customerId]);

  return (
    <section className="mt-8">
      <h2 className="font-medium text-stone-900">{customer ? customer.name : "Customer"}</h2>
      {error ? <p className="mt-3 text-sm text-red-700" role="alert">{error}</p> : null}
      {customer ? <p className="mt-2 text-sm text-stone-700">{customer.email}</p> : null}
      <ul className="mt-3 space-y-2 text-sm">
        {orders.map((order) => (
          <li key={order.id}>
            <Link className="underline" to={`/stores/${storeId}/orders/${order.id}`}>{order.number}</Link>
            {" · "}{formatCents(order.total_cents)} · {order.fulfillment_status}
          </li>
        ))}
      </ul>
    </section>
  );
}
