import { useEffect, useState, type FormEvent } from "react";
import { ApiError, errorText } from "../api/client";
import { commerceApi, uploadProductImage, type Product } from "../api/commerce";
import { formatCents, integerCents } from "../money";
import { StoreGate } from "./StoreFrame";

export default function ProductsPage() {
  return (
    <StoreGate>
      {(store) => <ProductManager storeId={store.id} canEdit={store.role === "owner" || store.role === "admin"} />}
    </StoreGate>
  );
}

export function ProductManager({ storeId, canEdit }: { storeId: number; canEdit: boolean }) {
  const [products, setProducts] = useState<Product[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [title, setTitle] = useState("");
  const [handle, setHandle] = useState("");
  const [sku, setSku] = useState("");
  const [price, setPrice] = useState("");
  const [onHand, setOnHand] = useState("0");

  async function reload() {
    const body = await commerceApi.products(storeId);
    setProducts(body.products);
  }

  useEffect(() => {
    let active = true;
    commerceApi.products(storeId).then((body) => {
      if (!active) return;
      setProducts(body.products);
      setLoaded(true);
    }).catch((caught: unknown) => {
      if (active) setError(errorText(caught));
    });
    return () => {
      active = false;
    };
  }, [storeId]);

  async function createProduct(event: FormEvent) {
    event.preventDefault();
    let priceCents: number;
    let quantity: number;
    try {
      priceCents = integerCents(price);
      quantity = integerCents(onHand);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Enter a whole number of cents.");
      return;
    }
    try {
      await commerceApi.createProduct(storeId, {
        title, handle, sku, price_cents: priceCents, on_hand: quantity, description: "",
      });
      setTitle("");
      setHandle("");
      setSku("");
      setPrice("");
      setError(null);
      await reload();
    } catch (caught) {
      setError(errorText(caught));
    }
  }

  return (
    <section className="mt-8">
      <h2 className="font-medium text-stone-900">Products</h2>
      {error ? <p className="mt-3 text-sm text-red-700" role="alert">{error}</p> : null}
      {loaded && products.length === 0 ? <p className="mt-3 text-sm text-stone-700">No products yet.</p> : null}
      <ul className="mt-3 divide-y divide-stone-200 rounded-lg border border-stone-200 bg-white">
        {products.map((product) => (
          <li key={product.id} className="px-4 py-3 text-sm">
            <div className="flex items-center justify-between gap-3">
              <span className="font-medium text-stone-900">{product.title}</span>
              <span className="text-stone-500">{product.status}</span>
            </div>
            <ul className="mt-2 space-y-2 text-stone-700">
              {(product.variants ?? []).map((variant) => (
                <li key={variant.id}>
                  <p>{variant.title} · {variant.sku} · {formatCents(variant.price_cents)} · {variant.on_hand ?? 0} on hand</p>
                  {canEdit ? (
                    <form className="mt-1 flex flex-wrap items-end gap-2" onSubmit={(event) => {
                      event.preventDefault();
                      const data = new FormData(event.currentTarget);
                      let nextPrice: number;
                      try {
                        nextPrice = integerCents(String(data.get("price_cents")));
                      } catch (caught) {
                        setError(caught instanceof Error ? caught.message : "Enter a whole number of cents.");
                        return;
                      }
                      void commerceApi.updateVariant(storeId, product.id, variant.id, nextPrice).then(reload).catch((caught: unknown) => setError(errorText(caught)));
                    }}>
                      <label className="text-sm" htmlFor={`price-${variant.id}`}>
                        New price in cents for {variant.sku}
                        <input id={`price-${variant.id}`} name="price_cents" defaultValue={variant.price_cents} className="mt-1 block w-36 rounded-md border border-stone-300 px-3 py-2" />
                      </label>
                      <button type="submit" className="rounded-md border border-stone-300 bg-white px-3 py-2 text-sm">Save price</button>
                    </form>
                  ) : null}
                </li>
              ))}
            </ul>
            {canEdit ? (
              <div className="mt-2 flex flex-wrap gap-2">
                <button type="button" className="text-sm text-stone-700 underline" onClick={() => void commerceApi.archiveProduct(storeId, product.id).then(reload).catch((caught: unknown) => setError(errorText(caught)))}>
                  Archive
                </button>
                <label className="text-sm text-stone-700">
                  Image
                  <input className="ml-2" type="file" accept="image/png,image/jpeg,image/webp" onChange={(event) => {
                    const file = event.target.files?.[0];
                    if (!file) return;
                    void uploadProductImage(storeId, product.id, file, product.title).then(reload).catch((caught: unknown) => {
                      setError(caught instanceof ApiError ? errorText(caught) : caught instanceof Error ? caught.message : "The image could not be uploaded.");
                    });
                  }} />
                </label>
              </div>
            ) : null}
          </li>
        ))}
      </ul>
      {canEdit ? (
        <form className="mt-4 grid gap-3" onSubmit={(event) => void createProduct(event)}>
          <label className="text-sm" htmlFor="product-title">Title
            <input id="product-title" className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2" value={title} onChange={(event) => setTitle(event.target.value)} required />
          </label>
          <label className="text-sm" htmlFor="product-handle">Handle
            <input id="product-handle" className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2" value={handle} onChange={(event) => setHandle(event.target.value)} required />
          </label>
          <label className="text-sm" htmlFor="product-sku">SKU
            <input id="product-sku" className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2" value={sku} onChange={(event) => setSku(event.target.value)} required />
          </label>
          <label className="text-sm" htmlFor="product-price">Price in cents
            <input id="product-price" className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2" value={price} onChange={(event) => setPrice(event.target.value)} required />
          </label>
          <label className="text-sm" htmlFor="product-stock">On hand
            <input id="product-stock" className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2" value={onHand} onChange={(event) => setOnHand(event.target.value)} required />
          </label>
          <button type="submit" className="w-fit rounded-md bg-stone-900 px-3 py-2 text-sm font-medium text-white">Create product</button>
        </form>
      ) : null}
    </section>
  );
}
