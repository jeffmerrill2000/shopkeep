import { useState, type FormEvent } from "react";
import { Link, useNavigate } from "react-router";
import { errorText } from "../api/client";
import { useAuth } from "../auth/AuthProvider";

export default function LoginPage() {
  const auth = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    const nextError = validateLogin(email, password);
    if (nextError) {
      setError(nextError);
      return;
    }
    setPending(true);
    setError(null);
    try {
      await auth.signIn(email, password);
      navigate("/stores");
    } catch (caught) {
      setError(errorText(caught));
    } finally {
      setPending(false);
    }
  }

  return (
    <main id="main" className="mx-auto flex min-h-svh max-w-md flex-col justify-center px-6 py-10">
      <p className="text-sm font-medium tracking-wide text-stone-600">ShopKeep</p>
      <h1 className="mt-2 text-3xl font-semibold text-stone-900">Sign in</h1>
      <p className="mt-3 text-sm text-stone-600">
        Local demo owner: demo@shopkeep.test / demodemo12345
      </p>
      <form className="mt-8 space-y-4" onSubmit={onSubmit} noValidate>
        <label className="block text-sm font-medium text-stone-800" htmlFor="email">
          Email
          <input
            id="email"
            type="email"
            autoComplete="username"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2"
          />
        </label>
        <label className="block text-sm font-medium text-stone-800" htmlFor="password">
          Password
          <input
            id="password"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            className="mt-1 w-full rounded-md border border-stone-300 px-3 py-2"
          />
        </label>
        {error ? <p className="text-sm text-red-700" role="alert">{error}</p> : null}
        <button
          type="submit"
          disabled={pending}
          className="w-full rounded-md bg-stone-900 px-4 py-2 font-medium text-white disabled:opacity-60"
        >
          {pending ? "Signing in…" : "Sign in"}
        </button>
      </form>
      <p className="mt-6 text-sm text-stone-600">
        New merchant? <Link className="font-medium text-stone-900" to="/register">Create a store</Link>
      </p>
    </main>
  );
}

export function validateLogin(email: string, password: string): string | null {
  if (!email.includes("@")) return "Enter a valid email address.";
  if (password.length < 12) return "Password must be at least 12 characters.";
  return null;
}
