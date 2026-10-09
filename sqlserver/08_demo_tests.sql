-- TechStore | SQL Server | 08: Pruebas de humo (demo)
-- Ejecuta un flujo completo y compara con el resultado esperado. Cada prueba devuelve
-- PASS o FAIL. Requiere haber corrido 00 a 07. Deja datos de prueba en la base; para
-- empezar de cero usar 99_reset_dev_drop_database.sql.
-- IMPORTANTE: todo va en UN solo lote (sin GO) porque comparte variables.
USE TechStore;
GO

SET NOCOUNT ON;

-- ---------- Preparación ----------
DECLARE @idRol INT = (SELECT ID_ROL FROM ROL WHERE NOMBRE = 'Cliente');
DECLARE @idCat INT = (SELECT ID_CATEGORIA FROM CATEGORIA WHERE NOMBRE = 'Laptops');
DECLARE @idMarca INT = (SELECT ID_MARCA FROM MARCA WHERE NOMBRE = 'Dell');

EXEC NEW_USUARIO @p_NOMBRE = 'Demo', @p_APELLIDOS = 'Cliente', @p_CORREO = 'demo@example.com',
     @p_CONTRASENIA = 'HASH_DE_EJEMPLO', @p_TELEFONO = NULL, @p_ID_ROL = @idRol;
EXEC NEW_PRODUCTO @p_NOMBRE = 'Demo Laptop', @p_DESCRIPCION = 'Producto de prueba', @p_PRECIO = 500.00,
     @p_STOCK = 10, @p_STOCK_MIN = 5, @p_ID_CATEGORIA = @idCat, @p_ID_MARCA = @idMarca;
INSERT INTO PROVEEDOR (NOMBRE, EMPRESA) VALUES ('Contacto Demo', 'Proveedor Demo');

DECLARE @idUsuario INT = (SELECT ID_USUARIO FROM USUARIO WHERE CORREO = 'demo@example.com');
DECLARE @idProd INT = (SELECT ID_PRODUCTO FROM PRODUCTO WHERE NOMBRE = 'Demo Laptop');
DECLARE @idVenta INT, @idVenta2 INT, @idVenta3 INT, @idCompra INT;
DECLARE @idProv INT = (SELECT TOP 1 ID_PROVEEDOR FROM PROVEEDOR WHERE EMPRESA = 'Proveedor Demo');

-- ---------- Prueba 1: venta con DOS líneas del mismo producto (3 + 2 + 2 = 7) ----------
-- Stock inicial 10 -> esperado 3. Total esperado 3500 (7 x 500).
EXEC NEW_VENTA @p_ID_USUARIO = @idUsuario, @p_IMPUESTO = 0, @p_DESCUENTO = 0, @p_ID_VENTA = @idVenta OUTPUT;
EXEC NEW_DETALLE_VENTA @p_ID_VENTA = @idVenta, @p_ID_PRODUCTO = @idProd, @p_CANTIDAD = 3;
EXEC NEW_DETALLE_VENTA @p_ID_VENTA = @idVenta, @p_ID_PRODUCTO = @idProd, @p_CANTIDAD = 2;
EXEC NEW_DETALLE_VENTA @p_ID_VENTA = @idVenta, @p_ID_PRODUCTO = @idProd, @p_CANTIDAD = 2;

SELECT 'Prueba 1: stock tras vender 3+2+2' AS PRUEBA, p.STOCK AS OBTENIDO, 3 AS ESPERADO,
       CASE WHEN p.STOCK = 3 THEN 'PASS' ELSE 'FAIL' END AS RESULTADO
FROM PRODUCTO p WHERE p.ID_PRODUCTO = @idProd;

SELECT 'Prueba 1b: total de la venta' AS PRUEBA, v.TOTAL AS OBTENIDO, 3500.00 AS ESPERADO,
       CASE WHEN v.TOTAL = 3500.00 THEN 'PASS' ELSE 'FAIL' END AS RESULTADO
FROM VENTA v WHERE v.ID_VENTA = @idVenta;

-- ---------- Prueba 2: cancelar la venta repone TODAS las líneas ----------
-- Esperado: stock vuelve a 10 (con el bug anterior solo reponía una línea).
EXEC UPD_ESTADO_VENTA @p_ID_VENTA = @idVenta, @p_ESTADO = 'Cancelada';

SELECT 'Prueba 2: stock tras cancelar' AS PRUEBA, p.STOCK AS OBTENIDO, 10 AS ESPERADO,
       CASE WHEN p.STOCK = 10 THEN 'PASS' ELSE 'FAIL' END AS RESULTADO
FROM PRODUCTO p WHERE p.ID_PRODUCTO = @idProd;

-- ---------- Prueba 3: stock insuficiente debe fallar y no tocar el stock ----------
EXEC NEW_VENTA @p_ID_USUARIO = @idUsuario, @p_IMPUESTO = 0, @p_DESCUENTO = 0, @p_ID_VENTA = @idVenta2 OUTPUT;
BEGIN TRY
    EXEC NEW_DETALLE_VENTA @p_ID_VENTA = @idVenta2, @p_ID_PRODUCTO = @idProd, @p_CANTIDAD = 999;
    SELECT 'Prueba 3: stock insuficiente' AS PRUEBA, 'No se lanzó error' AS MENSAJE, 'FAIL' AS RESULTADO;
END TRY
BEGIN CATCH
    SELECT 'Prueba 3: stock insuficiente' AS PRUEBA, ERROR_MESSAGE() AS MENSAJE,
           CASE WHEN (SELECT STOCK FROM PRODUCTO WHERE ID_PRODUCTO = @idProd) = 10
                THEN 'PASS' ELSE 'FAIL' END AS RESULTADO;
END CATCH;

-- ---------- Prueba 4: compra a proveedor con dos líneas del mismo producto (5 + 5) ----------
-- Stock 10 -> esperado 20 al marcar 'Recibida'. Total de la orden esperado 4000 (10 x 400).
EXEC NEW_COMPRA_PROVEEDOR @p_ID_PROVEEDOR = @idProv, @p_ID_COMPRA = @idCompra OUTPUT;
EXEC NEW_DETALLE_COMPRA @p_ID_COMPRA = @idCompra, @p_ID_PRODUCTO = @idProd, @p_CANTIDAD = 5, @p_PRECIO_COMPRA = 400;
EXEC NEW_DETALLE_COMPRA @p_ID_COMPRA = @idCompra, @p_ID_PRODUCTO = @idProd, @p_CANTIDAD = 5, @p_PRECIO_COMPRA = 400;
EXEC UPD_ESTADO_COMPRA @p_ID_COMPRA = @idCompra, @p_ESTADO = 'Recibida';

SELECT 'Prueba 4: stock tras recibir compra 5+5' AS PRUEBA, p.STOCK AS OBTENIDO, 20 AS ESPERADO,
       CASE WHEN p.STOCK = 20 THEN 'PASS' ELSE 'FAIL' END AS RESULTADO
FROM PRODUCTO p WHERE p.ID_PRODUCTO = @idProd;

SELECT 'Prueba 4b: total de la compra' AS PRUEBA, c.TOTAL AS OBTENIDO, 4000.00 AS ESPERADO,
       CASE WHEN c.TOTAL = 4000.00 THEN 'PASS' ELSE 'FAIL' END AS RESULTADO
FROM COMPRA_PROVEEDOR c WHERE c.ID_COMPRA = @idCompra;

-- ---------- Prueba 5: funciones (venta de 1 unidad completada) ----------
EXEC NEW_VENTA @p_ID_USUARIO = @idUsuario, @p_IMPUESTO = 0, @p_DESCUENTO = 0, @p_ID_VENTA = @idVenta3 OUTPUT;
EXEC NEW_DETALLE_VENTA @p_ID_VENTA = @idVenta3, @p_ID_PRODUCTO = @idProd, @p_CANTIDAD = 1;
EXEC UPD_ESTADO_VENTA @p_ID_VENTA = @idVenta3, @p_ESTADO = 'Completada';

SELECT 'Prueba 5: FN_PRODUCTO_MAS_VENDIDO' AS PRUEBA, dbo.FN_PRODUCTO_MAS_VENDIDO() AS OBTENIDO,
       'Demo Laptop' AS ESPERADO,
       CASE WHEN dbo.FN_PRODUCTO_MAS_VENDIDO() = 'Demo Laptop' THEN 'PASS' ELSE 'FAIL' END AS RESULTADO;

SELECT 'Prueba 5b: FN_TOTAL_GASTADO_USUARIO' AS PRUEBA, dbo.FN_TOTAL_GASTADO_USUARIO(@idUsuario) AS OBTENIDO,
       500.00 AS ESPERADO,
       CASE WHEN dbo.FN_TOTAL_GASTADO_USUARIO(@idUsuario) = 500.00 THEN 'PASS' ELSE 'FAIL' END AS RESULTADO;

-- ---------- Auditoría: movimientos que generaron los triggers ----------
SELECT * FROM VIS_HISTORIAL_INVENTARIO ORDER BY ID_MOVIMIENTO;
GO
