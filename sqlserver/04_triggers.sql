-- TechStore | SQL Server | 04: Triggers
-- En T-SQL un trigger se ejecuta una vez por sentencia y ve TODAS las filas afectadas
-- (tablas "inserted" y "deleted"), no fila por fila como en Oracle. Por eso las
-- cantidades se SUMAN por producto antes de actualizar el stock: un UPDATE ... FROM con
-- JOIN solo aplica UNA de las filas coincidentes, y habría descuadrado el stock cuando
-- una orden/venta tiene dos líneas del mismo producto.
-- SET XACT_ABORT ON: ante cualquier error el trigger deshace la transacción completa.
USE TechStore;
GO

-- Al insertar líneas de venta: valida stock, inserta, descuenta stock y registra la salida.
-- INSTEAD OF es el equivalente más cercano al BEFORE INSERT de Oracle (T-SQL no tiene BEFORE).
CREATE OR ALTER TRIGGER TRIG_STOCK_VENTA
ON DETALLE_VENTA
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (
        SELECT 1
        FROM (SELECT ID_PRODUCTO, SUM(CANTIDAD) AS CANTIDAD_TOTAL FROM inserted GROUP BY ID_PRODUCTO) i
        INNER JOIN PRODUCTO p ON p.ID_PRODUCTO = i.ID_PRODUCTO
        WHERE p.STOCK < i.CANTIDAD_TOTAL
    )
        THROW 50001, 'Stock insuficiente para el producto seleccionado', 1;

    INSERT INTO DETALLE_VENTA (CANTIDAD, PRECIO_UNITARIO, SUBTOTAL, ID_VENTA, ID_PRODUCTO)
    SELECT CANTIDAD, PRECIO_UNITARIO, SUBTOTAL, ID_VENTA, ID_PRODUCTO
    FROM inserted;

    UPDATE p
    SET p.STOCK = p.STOCK - i.CANTIDAD_TOTAL
    FROM PRODUCTO p
    INNER JOIN (SELECT ID_PRODUCTO, SUM(CANTIDAD) AS CANTIDAD_TOTAL FROM inserted GROUP BY ID_PRODUCTO) i
        ON i.ID_PRODUCTO = p.ID_PRODUCTO;

    INSERT INTO HISTORIAL_INVENTARIO (TIPO_MOVIMIENTO, CANTIDAD, OBSERVACION, ID_PRODUCTO)
    SELECT 'SALIDA', CANTIDAD, 'Salida por venta', ID_PRODUCTO
    FROM inserted;
END
GO

-- Al marcar una compra como 'Recibida': aumenta el stock de cada producto de la orden
CREATE OR ALTER TRIGGER TRIG_STOCK_COMPRA
ON COMPRA_PROVEEDOR
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT UPDATE(ESTADO)
        RETURN;

    UPDATE p
    SET p.STOCK = p.STOCK + x.CANTIDAD_TOTAL
    FROM PRODUCTO p
    INNER JOIN (
        SELECT dc.ID_PRODUCTO, SUM(dc.CANTIDAD) AS CANTIDAD_TOTAL
        FROM DETALLE_COMPRA dc
        INNER JOIN inserted i ON i.ID_COMPRA = dc.ID_COMPRA
        INNER JOIN deleted d ON d.ID_COMPRA = i.ID_COMPRA
        WHERE i.ESTADO = 'Recibida' AND d.ESTADO <> 'Recibida'
        GROUP BY dc.ID_PRODUCTO
    ) x ON x.ID_PRODUCTO = p.ID_PRODUCTO;

    INSERT INTO HISTORIAL_INVENTARIO (TIPO_MOVIMIENTO, CANTIDAD, OBSERVACION, ID_PRODUCTO)
    SELECT 'ENTRADA', dc.CANTIDAD, 'Entrada por compra a proveedor recibida', dc.ID_PRODUCTO
    FROM DETALLE_COMPRA dc
    INNER JOIN inserted i ON i.ID_COMPRA = dc.ID_COMPRA
    INNER JOIN deleted d ON d.ID_COMPRA = i.ID_COMPRA
    WHERE i.ESTADO = 'Recibida' AND d.ESTADO <> 'Recibida';
END
GO

-- Al cancelar una venta: devuelve el stock de cada línea y deja constancia
CREATE OR ALTER TRIGGER TRIG_REPOSICION_VENTA_CANCELADA
ON VENTA
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT UPDATE(ESTADO)
        RETURN;

    UPDATE p
    SET p.STOCK = p.STOCK + x.CANTIDAD_TOTAL
    FROM PRODUCTO p
    INNER JOIN (
        SELECT dv.ID_PRODUCTO, SUM(dv.CANTIDAD) AS CANTIDAD_TOTAL
        FROM DETALLE_VENTA dv
        INNER JOIN inserted i ON i.ID_VENTA = dv.ID_VENTA
        INNER JOIN deleted d ON d.ID_VENTA = i.ID_VENTA
        WHERE i.ESTADO = 'Cancelada' AND d.ESTADO <> 'Cancelada'
        GROUP BY dv.ID_PRODUCTO
    ) x ON x.ID_PRODUCTO = p.ID_PRODUCTO;

    INSERT INTO HISTORIAL_INVENTARIO (TIPO_MOVIMIENTO, CANTIDAD, OBSERVACION, ID_PRODUCTO)
    SELECT 'ENTRADA', dv.CANTIDAD, 'Reingreso por cancelación de venta', dv.ID_PRODUCTO
    FROM DETALLE_VENTA dv
    INNER JOIN inserted i ON i.ID_VENTA = dv.ID_VENTA
    INNER JOIN deleted d ON d.ID_VENTA = i.ID_VENTA
    WHERE i.ESTADO = 'Cancelada' AND d.ESTADO <> 'Cancelada';
END
GO
