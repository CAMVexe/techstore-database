-- TechStore | SQL Server | 07: Datos base (catálogo mínimo de arranque)
-- Roles para el login y categoría/marca para poblar los combos del formulario de productos.
-- El resto de los datos (usuarios, productos, ventas, carritos, compras) los genera la
-- aplicación web. Ejecutar UNA sola vez (no es idempotente).
USE TechStore;
GO

EXEC NEW_ROL 'Administrador', 'Acceso completo al sistema';
EXEC NEW_ROL 'Cliente', 'Usuario comprador de la tienda';

EXEC NEW_CATEGORIA 'Laptops', 'Computadoras portátiles';
EXEC NEW_CATEGORIA 'Accesorios', 'Periféricos y accesorios tecnológicos';

EXEC NEW_MARCA 'Dell', 'Estados Unidos';
EXEC NEW_MARCA 'Logitech', 'Suiza';
GO
