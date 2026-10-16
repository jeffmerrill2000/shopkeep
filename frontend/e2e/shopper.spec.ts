import { expect, test } from "@playwright/test";

test("a shopper buys the demo tee with a simulated payment", async ({ page }) => {
  await page.goto("/s/demo");
  await expect(page.getByRole("heading", { name: "Demo Store" })).toBeVisible();
  await page.getByRole("link", { name: "Demo Tee" }).click();
  await expect(page.getByRole("heading", { name: "Demo Tee" })).toBeVisible();
  await page.getByRole("button", { name: "Add to cart" }).click();
  await expect(page.getByRole("heading", { name: "Cart" })).toBeVisible();
  await expect(page.getByText("Demo Tee")).toBeVisible();
  await page.getByRole("link", { name: "Checkout" }).click();

  await page.getByLabel("Email").fill(`buyer-${test.info().parallelIndex}-${Math.floor(Math.random() * 1_000_000)}@shopkeep.test`);
  await page.getByLabel("Name").fill("Buyer");
  await page.getByLabel("Address").fill("1 Main");
  await page.getByLabel("City").fill("Austin");
  await page.getByLabel("Region").fill("TX");
  await page.getByLabel("Postal code").fill("78701");
  await page.getByLabel("Country").fill("US");
  await page.getByLabel("Discount code").fill("SAVE10");
  await page.getByRole("button", { name: "Place order" }).click();

  await expect(page.getByRole("heading", { name: "Order confirmed" })).toBeVisible();
  await expect(page.getByText("simulated")).toBeVisible();
  await expect(page.getByText(/\$2[0-9]\./)).toBeVisible();
});

test("an unknown store and a bad discount explain the failure", async ({ page }) => {
  await page.goto("/s/missing-store");
  await expect(page.getByRole("alert")).toBeVisible();

  await page.goto("/s/demo/products/tee");
  await page.getByRole("button", { name: "Add to cart" }).click();
  await page.getByRole("link", { name: "Checkout" }).click();
  await page.getByLabel("Email").fill(`bad-${test.info().parallelIndex}-${Math.floor(Math.random() * 1_000_000)}@shopkeep.test`);
  await page.getByLabel("Name").fill("Buyer");
  await page.getByLabel("Address").fill("1 Main");
  await page.getByLabel("City").fill("Austin");
  await page.getByLabel("Region").fill("TX");
  await page.getByLabel("Postal code").fill("78701");
  await page.getByLabel("Country").fill("US");
  await page.getByLabel("Discount code").fill("NOT-A-CODE");
  await page.getByRole("button", { name: "Place order" }).click();
  await expect(page.getByRole("alert")).toBeVisible();
  await expect(page.getByRole("heading", { name: "Checkout" })).toBeVisible();
});
