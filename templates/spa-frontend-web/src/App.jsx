import { Navigate, Route, Routes } from "react-router-dom";
import { MainLayout } from "./components/layout/MainLayout";
import { ROUTES } from "./constants/routes";
import { LoginPage } from "./pages/auth/LoginPage";
import { InventarioPage } from "./pages/inventario/InventarioPage";
import { ProtectedRoute } from "./services/auth/ProtectedRoute";

export default function App() {
  return (
    <Routes>
      <Route path={ROUTES.LOGIN} element={<LoginPage />} />
      <Route element={<ProtectedRoute />}>
        <Route element={<MainLayout />}>
          <Route path={ROUTES.INVENTARIO} element={<InventarioPage />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to={ROUTES.INVENTARIO} replace />} />
    </Routes>
  );
}
