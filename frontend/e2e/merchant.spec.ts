import { expect, test } from "@playwright/test";

test("merchant edits the catalog, fulfills an order, and signs out", async ({ page }) => {
  const suffix = `${test.info().parallelIndex}${Math.floor(Math.random() * 1_000_000)}`;
  const sku = `CAP${suffix}`;
  const title = `Cap ${suffix}`;
  const email = `buyer-${suffix}@shopkeep.test`;

  await page.goto("/login");
  await page.getByLabel("Email").fill("demo@shopkeep.test");
  await page.getByLabel("Password").fill("demodemo12345");
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.getByRole("link", { name: /Demo Store/ }).click();
  await expect(page.getByRole("heading", { name: "People" })).toBeVisible();
  await expect(page.getByText("Discount SAVE10")).toBeVisible();

  await page.getByRole("link", { name: "Products" }).click();
  await page.getByLabel("Title").fill(title);
  await page.getByLabel("Handle").fill(`cap-${suffix}`);
  await page.getByLabel("SKU").fill(sku);
  await page.getByLabel("Price in cents", { exact: true }).fill("10.99");
  await page.getByLabel("On hand").fill("3");
  await page.getByRole("button", { name: "Create product" }).click();
  await expect(page.getByRole("alert")).toHaveText(/whole number of cents/);

  await page.getByLabel("Price in cents", { exact: true }).fill("1800");
  await page.getByRole("button", { name: "Create product" }).click();
  const product = page.locator("form").filter({ hasText: sku });
  await expect(product).toBeVisible();
  await product.getByLabel(`New price in cents for ${sku}`).fill("1900");
  await product.getByRole("button", { name: "Save price" }).click();
  await expect(page.getByText(`${sku} · $19.00`)).toBeVisible();

  await page.getByRole("link", { name: "Inventory" }).click();
  await page.getByLabel("Item").selectOption({ label: sku });
  await page.getByLabel("Delta").fill("2");
  await page.getByRole("button", { name: "Adjust" }).click();
  await expect(page.locator("li").filter({ hasText: sku })).toContainText("5 on hand");

  await page.goto(`/s/demo/products/cap-${suffix}`);
  await page.getByRole("button", { name: "Add to cart" }).click();
  await page.getByRole("link", { name: "Checkout" }).click();
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Name").fill("Buyer");
  await page.getByLabel("Address").fill("1 Main");
  await page.getByLabel("City").fill("Austin");
  await page.getByLabel("Region").fill("TX");
  await page.getByLabel("Postal code").fill("78701");
  await page.getByLabel("Country").fill("US");
  await page.getByLabel("Discount code").fill("SAVE10");
  await page.getByRole("button", { name: "Place order" }).click();
  await expect(page.getByRole("heading", { name: "Order confirmed" })).toBeVisible();

  await page.goto("/stores");
  await page.getByRole("link", { name: /Demo Store/ }).click();
  await page.getByRole("link", { name: "Orders" }).click();
  await page.getByRole("link", { name: new RegExp(email) }).click();
  await page.getByLabel("Tracking").fill("TRACK-M7");
  await page.getByRole("button", { name: "Mark shipped" }).click();
  await expect(page.getByText("shipped")).toBeVisible();

  await page.getByRole("link", { name: "Customers" }).click();
  await page.getByRole("link", { name: new RegExp(email) }).click();
  await expect(page.getByRole("heading", { name: "Buyer" })).toBeVisible();
  await expect(page.getByText(email)).toBeVisible();

  await page.getByRole("link", { name: "Reports" }).click();
  await expect(page.getByText("Paid")).toBeVisible();

  await page.goto("/stores");
  await page.getByRole("button", { name: "Sign out" }).click();
  await expect(page.getByRole("heading", { name: "Sign in" })).toBeVisible();
});
