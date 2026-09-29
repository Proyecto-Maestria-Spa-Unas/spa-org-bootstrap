import { Navigate, Outlet } from "react-router-dom";
import { ROUTES } from "../../constants/routes";
import { useAuth } from "./AuthContext";

/** Protege rutas por autenticación y, opcionalmente, por rol (RF-01, RNF-07). */
export function ProtectedRoute({ roles }) {
  const { isAuthenticated, user } = useAuth();
  if (!isAuthenticated) return <Navigate to={ROUTES.LOGIN} replace />;
  if (roles && user && !roles.includes(user.rol)) return <Navigate to={ROUTES.INVENTARIO} replace />;
  return <Outlet />;
}
