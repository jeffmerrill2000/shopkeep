import type { components, paths } from "./schema";

export type User = components["schemas"]["User"];
export type Store = components["schemas"]["Store"];
export type Membership = components["schemas"]["Membership"];
export type AuditEvent = components["schemas"]["AuditEvent"];

type RegistrationBody = paths["/api/v1/registration"]["post"]["requestBody"]["content"]["application/json"];
type RegistrationResponse = paths["/api/v1/registration"]["post"]["responses"][201]["content"]["application/json"];
type SessionBody = paths["/api/v1/session"]["post"]["requestBody"]["content"]["application/json"];
type SessionResponse = paths["/api/v1/session"]["post"]["responses"][200]["content"]["application/json"];
type MeResponse = paths["/api/v1/me"]["get"]["responses"][200]["content"]["application/json"];
type StoreListResponse = paths["/api/v1/stores"]["get"]["responses"][200]["content"]["application/json"];
type StoreWriteBody = paths["/api/v1/stores"]["post"]["requestBody"]["content"]["application/json"];
type StoreResponse = paths["/api/v1/stores"]["post"]["responses"][201]["content"]["application/json"];
type MembershipListResponse = paths["/api/v1/stores/{store_id}/memberships"]["get"]["responses"][200]["content"]["application/json"];
type MembershipWriteBody = paths["/api/v1/stores/{store_id}/memberships"]["post"]["requestBody"]["content"]["application/json"];
type MembershipResponse = paths["/api/v1/stores/{store_id}/memberships"]["post"]["responses"][201]["content"]["application/json"];
type AuditListResponse = paths["/api/v1/stores/{store_id}/audit_events"]["get"]["responses"][200]["content"]["application/json"];

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly details: Record<string, string[]>;

  constructor(status: number, code: string, message: string, details: Record<string, string[]>) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

let csrfToken: string | null = null;

export function errorText(error: unknown): string {
  if (!(error instanceof ApiError)) return "The request could not be completed.";
  const fields = Object.entries(error.details).flatMap(([field, messages]) =>
    messages.map((message) => `${field} ${message}`),
  );
  return [error.message, ...fields].filter(Boolean).join(" ");
}

async function readError(response: Response): Promise<ApiError> {
  const payload: unknown = await response.json().catch(() => null);
  if (isErrorBody(payload)) {
    return new ApiError(response.status, payload.error.code, payload.error.message, payload.error.details);
  }
  return new ApiError(response.status, "error", "The request could not be completed.", {});
}

function isErrorBody(payload: unknown): payload is components["schemas"]["Error"] {
  if (typeof payload !== "object" || payload === null || !("error" in payload)) return false;
  const error = payload.error;
  return typeof error === "object" && error !== null && "code" in error && "message" in error && "details" in error;
}

export async function loadCsrf(): Promise<string> {
  const response = await fetch("/api/v1/csrf", { credentials: "include" });
  if (!response.ok) throw await readError(response);
  const body = (await response.json()) as paths["/api/v1/csrf"]["get"]["responses"][200]["content"]["application/json"];
  csrfToken = body.csrf_token;
  return body.csrf_token;
}

export async function api<T>(
  path: string,
  options: { method?: string; body?: unknown; headers?: Record<string, string> } = {},
  retry = true,
): Promise<T> {
  const method = options.method ?? "GET";
  const headers = new Headers({ Accept: "application/json" });
  for (const [name, value] of Object.entries(options.headers ?? {})) headers.set(name, value);
  if (options.body !== undefined) {
    if (!csrfToken) await loadCsrf();
    headers.set("Content-Type", "application/json");
    headers.set("X-CSRF-Token", csrfToken ?? "");
  }

  const response = await fetch(path, {
    method,
    credentials: "include",
    headers,
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });

  if (response.status === 204) return undefined as T;

  if (!response.ok) {
    const error = await readError(response);
    if (retry && error.code === "invalid_csrf") {
      csrfToken = null;
      await loadCsrf();
      return api<T>(path, options, false);
    }
    throw error;
  }

  return (await response.json()) as T;
}

export const sessionApi = {
  me: () => api<MeResponse>("/api/v1/me"),
  signIn: (body: SessionBody) => api<SessionResponse>("/api/v1/session", { method: "POST", body }),
  signOut: () => api<void>("/api/v1/session", { method: "DELETE", body: {} }),
  register: (body: RegistrationBody) => api<RegistrationResponse>("/api/v1/registration", { method: "POST", body }),
  stores: () => api<StoreListResponse>("/api/v1/stores"),
  createStore: (body: StoreWriteBody) => api<StoreResponse>("/api/v1/stores", { method: "POST", body }),
  updateStore: (id: number, body: { name?: string; currency?: string }) =>
    api<StoreResponse>(`/api/v1/stores/${id}`, { method: "PATCH", body }),
  memberships: (storeId: number) => api<MembershipListResponse>(`/api/v1/stores/${storeId}/memberships`),
  addMembership: (storeId: number, body: MembershipWriteBody) =>
    api<MembershipResponse>(`/api/v1/stores/${storeId}/memberships`, { method: "POST", body }),
  auditEvents: (storeId: number) => api<AuditListResponse>(`/api/v1/stores/${storeId}/audit_events`),
};
