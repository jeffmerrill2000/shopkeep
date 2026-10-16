import type { ReactNode } from "react";
import { Link, Navigate, NavLink, useParams } from "react-router";
import type { Store } from "../api/client";
import { useAuth } from "../auth/AuthProvider";

export default function StoreFrame({ store, children }: { store: Store; children: ReactNode }) {
  const link = "inline-flex items-center rounded-md px-2 py-1 text-sm text-stone-800 hover:bg-stone-200";
  return (
    <main id="main" className="mx-auto min-h-svh max-w-3xl px-4 py-8 sm:px-6 sm:py-10">
      <Link className="text-sm font-medium text-stone-600" to="/stores">All stores</Link>
      <h1 className="mt-3 text-3xl font-semibold break-words text-stone-900">{store.name}</h1>
      <p className="mt-2 text-stone-700">{store.handle} · {store.role} · {store.currency}</p>
      <nav className="mt-4 flex flex-wrap gap-2" aria-label="Store">
        <NavLink className={({ isActive }) => `${link} ${isActive ? "bg-stone-200 font-medium" : ""}`} to={`/stores/${store.id}`} end>Home</NavLink>
        <NavLink className={({ isActive }) => `${link} ${isActive ? "bg-stone-200 font-medium" : ""}`} to={`/stores/${store.id}/products`}>Products</NavLink>
        <NavLink className={({ isActive }) => `${link} ${isActive ? "bg-stone-200 font-medium" : ""}`} to={`/stores/${store.id}/inventory`}>Inventory</NavLink>
        <NavLink className={({ isActive }) => `${link} ${isActive ? "bg-stone-200 font-medium" : ""}`} to={`/stores/${store.id}/orders`}>Orders</NavLink>
        <NavLink className={({ isActive }) => `${link} ${isActive ? "bg-stone-200 font-medium" : ""}`} to={`/stores/${store.id}/customers`}>Customers</NavLink>
        <NavLink className={({ isActive }) => `${link} ${isActive ? "bg-stone-200 font-medium" : ""}`} to={`/stores/${store.id}/reports`}>Reports</NavLink>
        <Link className={link} to={`/s/${store.handle}`}>Storefront</Link>
      </nav>
      {children}
    </main>
  );
}

export function StoreGate({ children }: { children: (store: Store) => ReactNode }) {
  const auth = useAuth();
  const params = useParams();
  const store = auth.stores.find((item) => item.id === Number(params.storeId));
  if (!auth.ready) return <p className="px-6 py-10 text-stone-600">Checking your session…</p>;
  if (!auth.user) return <Navigate to="/login" replace />;
  if (!store) return <Navigate to="/stores" replace />;
  return <StoreFrame store={store}>{children(store)}</StoreFrame>;
}
