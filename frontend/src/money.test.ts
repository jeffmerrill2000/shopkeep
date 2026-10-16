import { describe, expect, it } from "vitest";
import { formatCents, integerCents } from "./money";

describe("money", () => {
  it("formats cents with integer division", () => {
    expect(formatCents(3416)).toBe("$34.16");
    expect(formatCents(5)).toBe("$0.05");
    expect(formatCents(0)).toBe("$0.00");
  });

  it("rejects a decimal price before it can be submitted", () => {
    expect(() => integerCents("10.99")).toThrow(/whole number of cents/);
    expect(() => integerCents("10.5")).toThrow(/whole number of cents/);
    expect(integerCents("2500")).toBe(2500);
  });
});
