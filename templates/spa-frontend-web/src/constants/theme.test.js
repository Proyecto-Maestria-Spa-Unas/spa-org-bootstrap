import { ESTADO_INVENTARIO } from "./theme";

it("define los cuatro estados del inventario (sección 10)", () => {
  expect(Object.keys(ESTADO_INVENTARIO)).toEqual(["DISPONIBLE", "BAJO_STOCK", "AGOTADO", "DESCONTINUADO"]);
});
