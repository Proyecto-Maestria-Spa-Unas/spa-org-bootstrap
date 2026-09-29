import { fireEvent, render, screen } from "@testing-library/react";
import { AuthProvider } from "./AuthProvider";
import { useAuth } from "./AuthContext";
import { apiClient, TOKEN_KEY } from "../api/client";

function Sonda() {
  const { isAuthenticated, user, login, logout } = useAuth();
  return (
    <>
      <span>{isAuthenticated ? `dentro:${user?.rol}` : "fuera"}</span>
      <button onClick={() => login("t-123", { rol: "ADMINISTRADOR" })}>entrar</button>
      <button onClick={logout}>salir</button>
    </>
  );
}

describe("AuthProvider", () => {
  beforeEach(() => sessionStorage.clear());

  it("login guarda el token y logout lo elimina (HU-01)", () => {
    render(<AuthProvider><Sonda /></AuthProvider>);
    expect(screen.getByText("fuera")).toBeInTheDocument();

    fireEvent.click(screen.getByText("entrar"));
    expect(screen.getByText("dentro:ADMINISTRADOR")).toBeInTheDocument();
    expect(sessionStorage.getItem(TOKEN_KEY)).toBe("t-123");

    fireEvent.click(screen.getByText("salir"));
    expect(screen.getByText("fuera")).toBeInTheDocument();
    expect(sessionStorage.getItem(TOKEN_KEY)).toBeNull();
  });

  it("el cliente HTTP adjunta el token Bearer", async () => {
    sessionStorage.setItem(TOKEN_KEY, "t-abc");
    const handler = apiClient.interceptors.request.handlers[0].fulfilled;
    const config = await handler({ headers: {} });
    expect(config.headers.Authorization).toBe("Bearer t-abc");
  });
});
