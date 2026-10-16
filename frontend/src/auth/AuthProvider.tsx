import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { ApiError, sessionApi, type Store, type User } from "../api/client";

type RegistrationInput = {
  email: string;
  password: string;
  name: string;
  store_name: string;
  handle: string;
  currency?: string;
};

type AuthState = {
  ready: boolean;
  user: User | null;
  stores: Store[];
  signIn: (email: string, password: string) => Promise<void>;
  register: (input: RegistrationInput) => Promise<void>;
  signOut: () => Promise<void>;
  refresh: () => Promise<void>;
};

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [ready, setReady] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const [stores, setStores] = useState<Store[]>([]);

  async function refresh() {
    try {
      const body = await sessionApi.me();
      setUser(body.user);
      setStores(body.stores ?? []);
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        setUser(null);
        setStores([]);
        return;
      }
      throw error;
    }
  }

  useEffect(() => {
    let active = true;
    refresh()
      .catch(() => {
        if (active) {
          setUser(null);
          setStores([]);
        }
      })
      .finally(() => {
        if (active) setReady(true);
      });
    return () => {
      active = false;
    };
  }, []);

  const value = useMemo<AuthState>(
    () => ({
      ready,
      user,
      stores,
      async signIn(email, password) {
        const body = await sessionApi.signIn({ email, password });
        setUser(body.user);
        setStores(body.stores ?? []);
      },
      async register(input) {
        const body = await sessionApi.register(input);
        setUser(body.user);
        setStores(body.store ? [body.store] : []);
      },
      async signOut() {
        await sessionApi.signOut();
        setUser(null);
        setStores([]);
      },
      refresh,
    }),
    [ready, stores, user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const value = useContext(AuthContext);
  if (!value) throw new Error("useAuth must be used within AuthProvider");
  return value;
}
