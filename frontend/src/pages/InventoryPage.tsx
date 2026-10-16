import { useEffect, useState, type FormEvent } from "react";
import { errorText } from "../api/client";
import { commerceApi, type InventoryItem } from "../api/commerce";
import { integerCents } from "../money";
import { StoreGate } from "./StoreFrame";

export default function InventoryPage() {
  return (
    <StoreGate>
      {(store) => <InventoryManager storeId={store.id} canEdit={store.role === "owner" || store.role === "admin"} />}
    </StoreGate>
  );
}

function InventoryManager({ storeId, canEdit }: { storeId: number; canEdit: boolean }) {
  const [items, setItems] = useState<InventoryItem[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [delta, setDelta] = useState("");
  const [reason, setReason] = useState("received");
  const [itemId, setItemId] = useState("");

  useEffect(() => {
    let active = true;
    commerceApi.inventory(storeId).then((body) => {
      if (!active) return;
      setItems(body.inventory_items);
      setItemId(String(body.inventory_items[0]?.id ?? ""));
    }).catch((caught: unknown) => {
      if (active) setError(errorText(caught));
    });
    return () => {
      active = false;
    };
  }, [storeId]);

  async function adjust(event: FormEvent) {
    event.preventDefault();
    try {
      const parsed = integerCents(delta.startsWith("-") ? delta.slice(1) : delta);
      const signed = delta.trim().startsWith("-") ? -parsed : parsed;
      if (signed === 0) throw new Error("Enter a non-zero quantity.");
      const body = await commerceApi.adjustInventory(storeId, Number(itemId), { delta: signed, reason });
      setItems((current) => current.map((item) => item.id === body.inventory_item.id ? body.inventory_item : item));
      setDelta("");
      setError(null);
    } catch (caught) {
      setError(caught instanceof Error && !("status" in caught) ? caught.message : errorText(caught));
    }
  }

  return (
    <section className="mt-8">
      <h2 className="font-medium text-stone-900">Inventory</h2>
      {error ? <p className="mt-3 text-sm text-red-700" role="alert">{error}</p> : null}
      <ul className="mt-3 divide-y divide-stone-200 rounded-lg border border-stone-200 bg-white">
        {items.map((item) => (
          <li key={item.id} className="flex justify-between px-4 py-3 text-sm">
            <span>{item.product_title} · {item.sku}</span>
            <span>{item.on_hand} on hand</span>
          </li>
        ))}
      </ul>
      {canEdit && items.length > 0 ? (
        <form className="mt-4 flex flex-wrap items-end gap-3" onSubmit={(event) => void adjust(event)}>
          <label className="text-sm" htmlFor="inventory-item">Item
            <select id="inventory-item" className="mt-1 block rounded-md border border-stone-300 px-3 py-2" value={itemId} onChange={(event) => setItemId(event.target.value)}>
              {items.map((item) => <option key={item.id} value={item.id}>{item.sku}</option>)}
            </select>
          </label>
          <label className="text-sm" htmlFor="inventory-delta">Delta
            <input id="inventory-delta" className="mt-1 block rounded-md border border-stone-300 px-3 py-2" value={delta} onChange={(event) => setDelta(event.target.value)} required />
          </label>
          <label className="text-sm" htmlFor="inventory-reason">Reason
            <select id="inventory-reason" className="mt-1 block rounded-md border border-stone-300 px-3 py-2" value={reason} onChange={(event) => setReason(event.target.value)}>
              <option value="received">received</option>
              <option value="correction">correction</option>
              <option value="damage">damage</option>
              <option value="return">return</option>
            </select>
          </label>
          <button type="submit" className="rounded-md bg-stone-900 px-3 py-2 text-sm font-medium text-white">Adjust</button>
        </form>
      ) : null}
    </section>
  );
}
