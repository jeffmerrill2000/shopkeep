export function integerCents(raw: string): number {
  const value = raw.trim();
  if (!/^[0-9]+$/.test(value)) {
    throw new Error("Enter a whole number of cents, with no decimal point.");
  }
  return Number(value);
}

export function formatCents(cents: number): string {
  const negative = cents < 0;
  const absolute = Math.abs(cents);
  const dollars = Math.floor(absolute / 100);
  const remainder = absolute % 100;
  return `${negative ? "-" : ""}$${dollars}.${String(remainder).padStart(2, "0")}`;
}
