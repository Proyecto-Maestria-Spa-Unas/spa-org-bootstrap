import { cn } from "./cn";

describe("cn", () => {
  it("combina cadenas, condiciones y objetos", () => {
    expect(cn("a", false, null, "b", { c: true, d: false })).toBe("a b c");
  });
});
