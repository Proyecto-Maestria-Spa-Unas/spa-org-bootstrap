/** Une clases CSS condicionales: cn("a", cond && "b", { c: true }) → "a b c" */
export function cn(...args) {
  return args
    .flatMap((arg) => {
      if (!arg) return [];
      if (typeof arg === "string") return [arg];
      if (typeof arg === "object") return Object.keys(arg).filter((k) => arg[k]);
      return [];
    })
    .join(" ");
}
