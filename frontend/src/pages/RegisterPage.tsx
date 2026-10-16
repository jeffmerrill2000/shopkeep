import { useState, type FormEvent } from "react";
import { Link, useNavigate } from "react-router";
import { errorText } from "../api/client";
import { useAuth } from "../auth/AuthProvider";

const HANDLE = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export default function RegisterPage() {
  const auth = useAuth();
  const navigate = useNavigate();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [storeName, setStoreName] = useState("");
  const [handle, setHandle] = useState("");
  const [currency, setCurrency] = useState("USD");
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    const nextError = validateRegistration({ name, email, password, storeName, handle, currency });
    if (nextError) {
      setError(nextError);
      return;
    }
    setPending(true);
    setError(null);
    try {
      await auth.register({
        name,
        email,
        password,
        store_name: storeName,
        handle,
        currency,
      });
      navigate("/stores");
    } catch (caught) {
      setError(errorText(caught));
    } finally {
      setPending(false);
    }
  }

  return (
    <main id="main" className="mx-auto flex min-h-svh max-w-md flex-col justify-center px-6 py-10">
      <p className="text-sm font-medium tracking-wide text-stone-500">ShopKeep</p>
      <h1 className="mt-2 text-3xl font-semibold text-stone-900">Create your store</h1>
      <form className="mt-8 space-y-4" onSubmit={onSubmit} noValidate>
        <Field id="name" label="Your name" value={name} onChange={setName} autoComplete="name" />
        <Field id="email" label="Email" type="email" value={email} onChange={setEmail} autoComplete="username" />
        <Field id="password" label="Password" type="password" value={password} onChange={setPassword} autoComplete="new-password" />
        <Field id="store-name" label="Store name" value={storeName} onChange={setStoreName} />
        <Field id="handle" label="Handle" value={handle} onChange={setHandle} />
        <Field id="currency" label="Currency" value={currency} onChange={setCurrency} />
        {error ? <p className="text-sm text-red-700" role="alert">{error}</p> : null}
        <button
          type="submit"
          disabled={pending}
          className="w-full rounded-md bg-stone-900 px-4 py-2 font-medium text-white disabled:opacity-60"
        >
          {pending ? "Creating…" : "Create store"}
        </button>
      </form>
      <p className="mt-6 text-sm text-stone-600">
        Already registered? <Link className="font-medium text-stone-900" to="/login">Sign in</Link>
      </p>
    </main>
  );
}

function Field({
  id,
  label,
  value,
  onChange,
  type = "text",
  autoComplete,
}: {
  id: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
  type?: string;
  autoComplete?: string;
}) {
  return (
    <label className="block text-sm font-medium text-stone-800" htmlFor={id}>
      {label}
      <input
        id={id}
        type={type}
        autoComplete={autoComplete}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2"
      />
    </label>
  );
}

export function validateRegistration(input: {
  name: string;
  email: string;
  password: string;
  storeName: string;
  handle: string;
  currency: string;
}): string | null {
  if (input.name.trim() === "") return "Enter your name.";
  if (!input.email.includes("@")) return "Enter a valid email address.";
  if (input.password.length < 12) return "Password must be at least 12 characters.";
  if (input.storeName.trim() === "") return "Enter a store name.";
  if (!HANDLE.test(input.handle)) return "Handle must be lowercase letters, numbers, and single hyphens.";
  if (!/^[A-Za-z]{3}$/.test(input.currency)) return "Currency must be a 3-letter code.";
  return null;
}
