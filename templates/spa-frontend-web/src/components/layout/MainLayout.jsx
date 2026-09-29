import { Outlet } from "react-router-dom";

export function MainLayout() {
  return (
    <div className="min-h-screen">
      <header className="border-b bg-white px-6 py-4">
        <h1 className="text-lg font-semibold text-pink-700">Spa de Uñas · Inventario</h1>
      </header>
      <main className="mx-auto max-w-6xl p-6">
        <Outlet />
      </main>
    </div>
  );
}
