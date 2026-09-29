import { cn } from "../../utils/cn";

const VARIANTS = {
  primary: "bg-pink-600 text-white hover:bg-pink-700",
  secondary: "bg-white text-slate-800 border border-slate-300 hover:bg-slate-50",
  danger: "bg-rose-600 text-white hover:bg-rose-700",
};

export function Button({ variant = "primary", className, ...props }) {
  return (
    <button
      className={cn("rounded-lg px-4 py-2 text-sm font-medium transition disabled:opacity-50", VARIANTS[variant], className)}
      {...props}
    />
  );
}
