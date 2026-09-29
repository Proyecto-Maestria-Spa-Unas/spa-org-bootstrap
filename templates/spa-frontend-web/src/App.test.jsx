import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import App from "./App";
import { AuthProvider } from "./services/auth/AuthProvider";
import { useAuth } from "./services/auth/AuthContext";
import { Button } from "./components/ui/Button";

function renderAt(path) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <AuthProvider>
        <App />
      </AuthProvider>
    </MemoryRouter>,
  );
}

describe("App", () => {
  beforeEach(() => sessionStorage.clear());

  it("redirige al login cuando no hay sesión (RNF-07)", () => {
    renderAt("/inventario");
    expect(screen.getByRole("heading", { name: "Ingresar" })).toBeInTheDocument();
  });

  it("muestra el inventario con sesión activa", () => {
    sessionStorage.setItem("spa.token", "token-de-prueba");
    renderAt("/inventario");
    expect(screen.getByRole("heading", { name: "Inventario" })).toBeInTheDocument();
  });

  it("useAuth fuera del proveedor lanza error", () => {
    function Sonda() {
      useAuth();
      return null;
    }
    expect(() => render(<Sonda />)).toThrow("useAuth");
  });

  it("Button aplica la variante", () => {
    render(<Button variant="danger">Borrar</Button>);
    expect(screen.getByRole("button", { name: "Borrar" }).className).toContain("bg-rose-600");
  });
});
