import { fireEvent, render, screen } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { AuthProvider } from "../auth/AuthProvider";
import ProductsPage from "./ProductsPage";

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

describe("product price entry", () => {
  beforeEach(() => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
        const url = String(input);
        if (url.endsWith("/api/v1/me")) {
          return json(200, {
            user: { id: 1, email: "demo@shopkeep.test", name: "Demo" },
            stores: [{ id: 7, merchant_id: 1, name: "Demo Store", handle: "demo", currency: "USD", status: "active", role: "owner" }],
          });
        }
        if (url.includes("/products") && init?.method === "POST") {
          return json(201, { product: { id: 1 } });
        }
        if (url.includes("/products")) return json(200, { products: [] });
        return json(200, {});
      }),
    );
  });

  it("rejects a decimal price before submit", async () => {
    render(
      <MemoryRouter initialEntries={["/stores/7/products"]}>
        <AuthProvider>
          <Routes>
            <Route path="/stores/:storeId/products" element={<ProductsPage />} />
          </Routes>
        </AuthProvider>
      </MemoryRouter>,
    );

    fireEvent.change(await screen.findByLabelText("Title"), { target: { value: "Hat" } });
    fireEvent.change(screen.getByLabelText("Handle"), { target: { value: "hat" } });
    fireEvent.change(screen.getByLabelText("SKU"), { target: { value: "HAT" } });
    fireEvent.change(screen.getByLabelText("Price in cents"), { target: { value: "10.99" } });
    fireEvent.click(screen.getByRole("button", { name: "Create product" }));

    expect(await screen.findByRole("alert")).toHaveTextContent("whole number of cents");
    const calls = vi.mocked(fetch).mock.calls.map(([url, init]) => [String(url), init?.method]);
    expect(calls.some(([url, method]) => String(url).includes("/products") && method === "POST")).toBe(false);
  });
});
