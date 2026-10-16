import { useEffect, useState } from "react";
import { errorText } from "../api/client";
import { commerceApi, type SalesSummary } from "../api/commerce";
import { formatCents } from "../money";
import { StoreGate } from "./StoreFrame";

export default function ReportsPage() {
  return (
    <StoreGate>
      {(store) => <Report storeId={store.id} />}
    </StoreGate>
  );
}

function Report({ storeId }: { storeId: number }) {
  const [summary, setSummary] = useState<SalesSummary | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    commerceApi.summary(storeId).then((body) => {
      if (active) setSummary(body.sales_summary);
    }).catch((caught: unknown) => {
      if (active) setError(errorText(caught));
    });
    return () => {
      active = false;
    };
  }, [storeId]);

  return (
    <section className="mt-8">
      <h2 className="font-medium text-stone-900">Sales summary</h2>
      {error ? <p className="mt-3 text-sm text-red-700" role="alert">{error}</p> : null}
      {summary ? (
        <dl className="mt-3 grid grid-cols-1 gap-3 text-sm sm:grid-cols-3">
          <div className="rounded-lg border border-stone-200 bg-white p-3"><dt className="text-stone-500">Orders</dt><dd className="text-xl">{summary.order_count}</dd></div>
          <div className="rounded-lg border border-stone-200 bg-white p-3"><dt className="text-stone-500">Paid</dt><dd className="text-xl">{formatCents(summary.paid_total_cents)}</dd></div>
          <div className="rounded-lg border border-stone-200 bg-white p-3"><dt className="text-stone-500">Units</dt><dd className="text-xl">{summary.units_sold}</dd></div>
        </dl>
      ) : null}
    </section>
  );
}
