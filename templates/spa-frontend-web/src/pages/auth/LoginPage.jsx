import { Button } from "../../components/ui/Button";

/** HU-01 · Autenticación (implementación pendiente del endpoint /auth/login). */
export function LoginPage() {
  return (
    <section className="mx-auto mt-24 max-w-sm rounded-xl bg-white p-8 shadow">
      <h2 className="mb-6 text-xl font-semibold">Ingresar</h2>
      <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
        <input aria-label="Usuario" className="w-full rounded border p-2" placeholder="Usuario" />
        <input aria-label="Contraseña" type="password" className="w-full rounded border p-2" placeholder="Contraseña" />
        <Button type="submit" className="w-full">Ingresar</Button>
      </form>
    </section>
  );
}
