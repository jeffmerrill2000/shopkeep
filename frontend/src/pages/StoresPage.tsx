import { Link, Navigate } from "react-router";
import { useAuth } from "../auth/AuthProvider";

export default function StoresPage() {
  const auth = useAuth();

  if (!auth.ready) return <Status text="Checking your session…" />;
  if (!auth.user) return <Navigate to="/login" replace />;

  return (
    <main id="main" className="mx-auto min-h-svh max-w-3xl px-6 py-10">
      <header className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-medium tracking-wide text-stone-600">ShopKeep</p>
          <h1 className="mt-2 text-3xl font-semibold text-stone-900">Your stores</h1>
          <p className="mt-2 text-stone-600">Signed in as {auth.user.email}</p>
        </div>
        <button type="button" className="text-sm font-medium text-stone-700" onClick={() => void auth.signOut()}>
          Sign out
        </button>
      </header>
      {auth.stores.length === 0 ? (
        <p className="mt-8 text-stone-600">You do not belong to a store yet.</p>
      ) : (
        <ul className="mt-8 divide-y divide-stone-200 rounded-lg border border-stone-200 bg-white">
          {auth.stores.map((store) => (
            <li key={store.id}>
              <Link className="block px-4 py-3 hover:bg-stone-50" to={`/stores/${store.id}`}>
                <span className="font-medium text-stone-900">{store.name}</span>
                <span className="mt-1 block text-sm text-stone-500">{store.handle} · {store.role} · {store.currency}</span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}

function Status({ text }: { text: string }) {
  return <p className="px-6 py-10 text-stone-600">{text}</p>;
}
