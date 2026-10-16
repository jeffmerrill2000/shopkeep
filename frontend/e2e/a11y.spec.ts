import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Page } from "@playwright/test";

async function expectNoSeriousViolations(page: Page) {
  const results = await new AxeBuilder({ page }).analyze();
  const serious = results.violations.filter((violation) => violation.impact === "serious" || violation.impact === "critical");
  expect(serious.map((violation) => `${violation.id}: ${violation.help}`)).toEqual([]);
}

test("public pages have no serious accessibility violations", async ({ page }) => {
  await page.goto("/login");
  await page.keyboard.press("Tab");
  await expect(page.getByRole("link", { name: "Skip to content" })).toBeFocused();
  await expectNoSeriousViolations(page);
  await page.goto("/register");
  await expectNoSeriousViolations(page);
  await page.goto("/s/demo");
  await expect(page.getByRole("heading", { name: "Demo Store" })).toBeVisible();
  await expectNoSeriousViolations(page);
  await page.goto("/s/demo/products/tee");
  await expect(page.getByRole("heading", { name: "Demo Tee" })).toBeVisible();
  await expectNoSeriousViolations(page);
  await page.goto("/s/demo/cart");
  await expect(page.getByRole("heading", { name: "Cart" })).toBeVisible();
  await expectNoSeriousViolations(page);
  await page.goto("/s/demo/checkout");
  await expect(page.getByText("Your cart is empty")).toBeVisible();
  await expectNoSeriousViolations(page);
  await page.goto("/s/missing-store");
  await expect(page.getByRole("alert")).toBeVisible();
  await expectNoSeriousViolations(page);
});

test("the merchant home has no serious accessibility violations", async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel("Email").fill("demo@shopkeep.test");
  await page.getByLabel("Password").fill("demodemo12345");
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.getByRole("link", { name: /Demo Store/ }).click();
  await expect(page.getByRole("heading", { name: "People" })).toBeVisible();
  await expectNoSeriousViolations(page);
});
