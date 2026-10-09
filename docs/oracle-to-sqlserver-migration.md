# Oracle PL/SQL → SQL Server T-SQL: migration notes

The database was first built in Oracle (PL/SQL) and then migrated to SQL Server (T-SQL).
This document lists what had to change and why. The SQL Server version is the maintained one.

## Syntax and types

| Topic | Oracle | SQL Server |
|---|---|---|
| Auto-increment key | `NUMBER GENERATED ALWAYS AS IDENTITY` | `INT IDENTITY(1,1)` |
| Numbers / text | `NUMBER`, `NUMBER(10,2)`, `VARCHAR2` | `INT`, `DECIMAL(10,2)`, `VARCHAR` |
| Date + current date | `DATE`, `SYSDATE` | `DATETIME`, `GETDATE()` |
| Null replacement | `NVL(x, 0)` | `ISNULL(x, 0)` |
| String concatenation | `a \|\| ' ' \|\| b` | `a + ' ' + b` |
| Parameters | `p_NOMBRE VARCHAR2` | `@p_NOMBRE VARCHAR(50)` (`@` prefix, explicit length) |
| Output parameter | `p_ID OUT NUMBER` + `RETURNING ID INTO p_ID` | `@p_ID INT OUTPUT` + `SCOPE_IDENTITY()` |
| Batch separator | `/` | `GO` |
| Top-N | `WHERE ROWNUM = 1` on a sorted subquery | `SELECT TOP 1 ... ORDER BY` |
| Calling a scalar function | `SELECT FN_X() FROM DUAL` | `SELECT dbo.FN_X()` (schema prefix required) |
| Views with `ORDER BY` | allowed | not allowed (order when querying) |

## Behavior that changed

- **Transactions.** Oracle procedures here end with `COMMIT`, so each procedure commits on its own
  and can't be composed into a larger transaction. The SQL Server versions that touch several tables
  use `BEGIN TRY / BEGIN TRANSACTION / COMMIT / CATCH / ROLLBACK / THROW`, which nests correctly
  inside a transaction opened by the caller.
- **Errors.** `RAISE_APPLICATION_ERROR(-20001, ...)` became `THROW 50001, ...`
  (user-defined error numbers 50000+).
- **Triggers are the biggest difference.**
  - Oracle `BEFORE INSERT ... FOR EACH ROW` sees one row at a time. T-SQL has no `BEFORE` triggers
    and no `FOR EACH ROW`: the closest equivalent is `INSTEAD OF INSERT`, which runs once per
    statement and receives *all* rows in the `inserted` table.
  - Oracle's `AFTER UPDATE OF ESTADO ... WHEN (NEW.ESTADO = ... AND OLD.ESTADO != ...)` became
    `AFTER UPDATE` + `IF UPDATE(ESTADO)` + a join between `inserted` and `deleted`.
  - The Oracle `FOR fila IN (...) LOOP` became set-based SQL. **Pitfall found in review:** a plain
    `UPDATE p ... FROM PRODUCTO p JOIN DETALLE_x ...` applies only one of several matching rows, so
    two lines of the same product in one order updated the stock once. Fix: `SUM(...) GROUP BY`
    product before updating. Covered by tests 1, 2 and 4 in `sqlserver/08_demo_tests.sql`.
- **Date arithmetic.** Oracle `SYSDATE - v.FECHA <= 30` yields fractional days.
  `DATEDIFF(DAY, ...)` counts calendar-date boundaries crossed, so the warranty window can differ
  by up to a day.

## Fixes that exist only in the SQL Server version

- Seed procedures `NEW_ROL`, `NEW_CATEGORIA`, `NEW_MARCA` (the previous script called them without defining them).
- Stock triggers aggregate quantities per product (see above).
- `NEW_DETALLE_VENTA` reads the unit price from `PRODUCTO` (it no longer trusts the caller) and only
  sells active products. **Breaking change:** the `@p_PRECIO_UNITARIO` parameter was removed.
- `UPD_ESTADO_GARANTIA` sets `FECHA_RESOLUCION` only when the warranty is approved or rejected.
- `FN_PRODUCTO_MAS_VENDIDO` counts only completed sales and groups by product id.
- Extra foreign-key indexes and a filtered unique index that enforces "one active cart per user".
- `NEW_DETALLE_COMPRA`, `DEL_USUARIO`, `DEL_PRODUCTO` run in a transaction.

## Differences left in the Oracle script (not maintained)

- `UPD_PRODUCTO` doesn't update category/brand.
- `NEW_DETALLE_VENTA` total isn't NULL-safe if `IMPUESTO`/`DESCUENTO` are NULL.
- Still has the caller-supplied unit price, the old `FN_PRODUCTO_MAS_VENDIDO` and `FECHA_RESOLUCION` behavior.
- Fewer indexes and no unique-active-cart rule.
- Its row-level triggers don't have the duplicate-line problem.
