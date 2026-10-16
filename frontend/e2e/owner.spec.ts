import { expect, test } from "@playwright/test";

test("demo owner sees the demo store and not the other merchant", async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel("Email").fill("demo@shopkeep.test");
  await page.getByLabel("Password").fill("demodemo12345");
  await page.getByRole("button", { name: "Sign in" }).click();

  await expect(page.getByRole("heading", { name: "Your stores" })).toBeVisible();
  await expect(page.getByRole("link", { name: /Demo Store/ })).toBeVisible();
  await expect(page.getByText("other-store")).toHaveCount(0);
  await expect(page.getByText("Other Store")).toHaveCount(0);

  await page.getByRole("link", { name: /Demo Store/ }).click();
  await expect(page.getByRole("heading", { name: "Demo Store" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "People" })).toBeVisible();
  await expect(page.getByText("demo@shopkeep.test")).toBeVisible();
});
