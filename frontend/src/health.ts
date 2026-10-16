export type HealthReport = {
  status: "ok" | "error";
  database: "ok" | "error";
  redis: "ok" | "error";
};

export async function fetchHealth(signal?: AbortSignal): Promise<HealthReport> {
  const response = await fetch("/api/v1/health", { signal });
  if (!response.ok && response.status !== 503) {
    throw new Error(`Health check failed (${response.status})`);
  }
  return (await response.json()) as HealthReport;
}
