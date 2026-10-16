import { fireEvent, render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { AuthProvider } from "./auth/AuthProvider";
import LoginPage from "./pages/LoginPage";
import RegisterPage from "./pages/RegisterPage";

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

describe("authentication screens", () => {
  beforeEach(() => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async (input: RequestInfo | URL) => {
        const url = String(input);
        if (url.includes("/api/v1/registration")) {
          return json(422, {
            error: {
              code: "invalid",
              message: "Validation failed",
              details: { email: ["has already been taken"] },
            },
          });
        }
        if (url.includes("/api/v1/session")) {
          return json(401, {
            error: {
              code: "invalid_credentials",
              message: "Email or password is incorrect",
              details: {},
            },
          });
        }
        if (url.includes("/api/v1/csrf")) return json(200, { csrf_token: "csrf-token" });
        return json(401, { error: { code: "unauthenticated", message: "Sign in required", details: {} } });
      }),
    );
  });

  it("rejects a short password before calling the session API", async () => {
    render(
      <MemoryRouter>
        <AuthProvider>
          <LoginPage />
        </AuthProvider>
      </MemoryRouter>,
    );

    fireEvent.change(await screen.findByLabelText("Email"), { target: { value: "owner@shopkeep.test" } });
    fireEvent.change(screen.getByLabelText("Password"), { target: { value: "short" } });
    fireEvent.click(screen.getByRole("button", { name: "Sign in" }));

    expect(await screen.findByRole("alert")).toHaveTextContent("Password must be at least 12 characters.");
    const calls = vi.mocked(fetch).mock.calls.map(([url]) => String(url));
    expect(calls.some((url) => url.includes("/api/v1/session"))).toBe(false);
  });

  it("shows an API authentication error", async () => {
    render(
      <MemoryRouter>
        <AuthProvider>
          <LoginPage />
        </AuthProvider>
      </MemoryRouter>,
    );

    fireEvent.change(await screen.findByLabelText("Email"), { target: { value: "owner@shopkeep.test" } });
    fireEvent.change(screen.getByLabelText("Password"), { target: { value: "passwordpassword" } });
    fireEvent.click(screen.getByRole("button", { name: "Sign in" }));

    expect(await screen.findByRole("alert")).toHaveTextContent("Email or password is incorrect");
  });

  it("shows a 422 field error from registration", async () => {
    render(
      <MemoryRouter>
        <AuthProvider>
          <RegisterPage />
        </AuthProvider>
      </MemoryRouter>,
    );

    fireEvent.change(await screen.findByLabelText("Your name"), { target: { value: "Owner" } });
    fireEvent.change(screen.getByLabelText("Email"), { target: { value: "owner@shopkeep.test" } });
    fireEvent.change(screen.getByLabelText("Password"), { target: { value: "passwordpassword" } });
    fireEvent.change(screen.getByLabelText("Store name"), { target: { value: "Demo" } });
    fireEvent.change(screen.getByLabelText("Handle"), { target: { value: "demo-two" } });
    fireEvent.click(screen.getByRole("button", { name: "Create store" }));

    expect(await screen.findByRole("alert")).toHaveTextContent("email has already been taken");
  });
});
