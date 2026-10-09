-- TechStore | SQL Server | 03: Funciones escalares
-- Se invocan con el esquema: SELECT dbo.FN_PRODUCTOS_STOCK_BAJO();
USE TechStore;
GO

-- Cantidad de productos activos en o por debajo de su stock mínimo
CREATE OR ALTER FUNCTION dbo.FN_PRODUCTOS_STOCK_BAJO() RETURNS INT AS
BEGIN
    DECLARE @v_CANTIDAD INT;
    SELECT @v_CANTIDAD = COUNT(*) FROM PRODUCTO WHERE STOCK <= STOCK_MIN AND ESTADO = 'Activo';
    RETURN @v_CANTIDAD;
END
GO

-- Total gastado por un usuario en ventas completadas
CREATE OR ALTER FUNCTION dbo.FN_TOTAL_GASTADO_USUARIO(@p_ID_USUARIO INT) RETURNS DECIMAL(10,2) AS
BEGIN
    DECLARE @v_TOTAL DECIMAL(10,2);
    SELECT @v_TOTAL = ISNULL(SUM(TOTAL), 0)
    FROM VENTA
    WHERE ID_USUARIO = @p_ID_USUARIO AND ESTADO = 'Completada';
    RETURN @v_TOTAL;
END
GO

-- CAMBIO vs. versión anterior: solo cuenta ventas 'Completada' (antes contaba también
-- las canceladas) y agrupa por ID de producto, no por nombre. Desempata por nombre.
CREATE OR ALTER FUNCTION dbo.FN_PRODUCTO_MAS_VENDIDO() RETURNS VARCHAR(80) AS
BEGIN
    DECLARE @v_NOMBRE VARCHAR(80);
    SELECT TOP 1 @v_NOMBRE = p.NOMBRE
    FROM DETALLE_VENTA dv
    JOIN VENTA ve ON ve.ID_VENTA = dv.ID_VENTA
    JOIN PRODUCTO p ON p.ID_PRODUCTO = dv.ID_PRODUCTO
    WHERE ve.ESTADO = 'Completada'
    GROUP BY p.ID_PRODUCTO, p.NOMBRE
    ORDER BY SUM(dv.CANTIDAD) DESC, p.NOMBRE;
    RETURN ISNULL(@v_NOMBRE, 'Sin ventas registradas');
END
GO

-- Garantía vigente si la venta tiene 30 días o menos.
-- Ojo: DATEDIFF(DAY, ...) cuenta cambios de fecha de calendario, no períodos de 24 h
-- (en Oracle, SYSDATE - fecha da días fraccionarios). Ver docs de migración.
CREATE OR ALTER FUNCTION dbo.FN_GARANTIA_VIGENTE(@p_ID_DETALLE_VENTA INT) RETURNS VARCHAR(20) AS
BEGIN
    DECLARE @v_FECHA DATETIME;
    SELECT @v_FECHA = v.FECHA
    FROM VENTA v
    JOIN DETALLE_VENTA dv ON dv.ID_VENTA = v.ID_VENTA
    WHERE dv.ID_DETALLE_VENTA = @p_ID_DETALLE_VENTA;

    IF @v_FECHA IS NULL RETURN 'No aplica';
    IF DATEDIFF(DAY, @v_FECHA, GETDATE()) <= 30 RETURN 'Vigente';
    RETURN 'Vencida';
END
GO
