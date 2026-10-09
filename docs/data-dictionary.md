# Data Dictionary

> Original university deliverable, kept in Spanish. Table names have no `TBL_` prefix here to
> match the SQL scripts. Where the scripts and this dictionary differ, the scripts are the source of truth.

## ROL

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_ROL` | INT | Número identificador del rol | Llave primaria |
| `NOMBRE` | VARCHAR(30) | Nombre del rol | NOT NULL |
| `DESCRIPCION` | VARCHAR(100) | Descripción del rol | Null permitido |

## CATEGORIA

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_CATEGORIA` | INT | Número identificador de la categoría | Llave primaria |
| `NOMBRE` | VARCHAR(40) | Nombre de la categoría | NOT NULL |
| `DESCRIPCION` | VARCHAR(150) | Descripción de la categoría | Null permitido |

## MARCA

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_MARCA` | INT | Número identificador de la marca | Llave primaria |
| `NOMBRE` | VARCHAR(40) | Nombre de la marca | NOT NULL |
| `PAIS_ORIGEN` | VARCHAR(40) | País de origen de la marca | Null permitido |

## PROVEEDOR

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_PROVEEDOR` | INT | Número identificador del proveedor | Llave primaria |
| `NOMBRE` | VARCHAR(60) | Nombre de contacto del proveedor | NOT NULL |
| `EMPRESA` | VARCHAR(60) | Nombre de la empresa proveedora | Null permitido |
| `TELEFONO` | VARCHAR(20) | Teléfono de contacto del proveedor | Null permitido |
| `CORREO` | VARCHAR(80) | Correo de contacto del proveedor | Null permitido |
| `SITIO_WEB` | VARCHAR(120) | Sitio web de la empresa proveedora | Null permitido |

## USUARIO

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_USUARIO` | INT | Número identificador del usuario | Llave primaria |
| `NOMBRE` | VARCHAR(50) | Nombre del usuario | NOT NULL |
| `APELLIDOS` | VARCHAR(50) | Apellidos del usuario | NOT NULL |
| `CORREO` | VARCHAR(80) | Correo electrónico del usuario | NOT NULL / UNIQUE (usado para login) |
| `CONTRASENIA` | VARCHAR(200) | Contraseña del usuario | NOT NULL. Se almacena ya hasheada (hash generado en C#, nunca texto plano) |
| `TELEFONO` | VARCHAR(20) | Teléfono del usuario | Null permitido |
| `FECHA_REGISTRO` | DATETIME | Fecha de registro del usuario | DEFAULT GETDATE(). Formato interno (AAAA-MM-DD) |
| `ESTADO` | VARCHAR(15) | Estado de la cuenta | DEFAULT 'Activo'. Valores permitidos: Activo, Inactivo |
| `ID_ROL` | INT | Número identificador del rol asociado | Llave foránea -> ROL(ID_ROL) |

## PRODUCTO

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_PRODUCTO` | INT | Número identificador del producto | Llave primaria |
| `NOMBRE` | VARCHAR(80) | Nombre del producto | NOT NULL |
| `DESCRIPCION` | VARCHAR(300) | Descripción del producto | Null permitido |
| `PRECIO` | DECIMAL(10,2) | Precio de venta actual del producto | NOT NULL. CHECK: PRECIO >= 0 |
| `STOCK` | INT | Cantidad actual disponible en inventario | DEFAULT 0. CHECK: STOCK >= 0. Se actualiza automáticamente vía triggers |
| `STOCK_MIN` | INT | Cantidad mínima antes de alertar reabastecimiento | DEFAULT 5 |
| `ESTADO` | VARCHAR(15) | Visibilidad del producto en el catálogo | DEFAULT 'Activo'. Valores permitidos: Activo, Inactivo. No indica disponibilidad de stock, solo si el admin lo desactivó |
| `ID_CATEGORIA` | INT | Número identificador de la categoría | Llave foránea -> CATEGORIA(ID_CATEGORIA) |
| `ID_MARCA` | INT | Número identificador de la marca | Llave foránea -> MARCA(ID_MARCA) |

## VENTA

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_VENTA` | INT | Número identificador de la venta | Llave primaria (cabecera) |
| `FECHA` | DATETIME | Fecha en que se generó la venta | DEFAULT GETDATE() |
| `IMPUESTO` | DECIMAL(10,2) | Monto de impuesto aplicado a la venta | DEFAULT 0 |
| `DESCUENTO` | DECIMAL(10,2) | Monto de descuento aplicado a la venta | DEFAULT 0 |
| `TOTAL` | DECIMAL(10,2) | Total final de la venta | DEFAULT 0. Se recalcula automáticamente al agregar líneas: SUMA(subtotales) + IMPUESTO - DESCUENTO |
| `ESTADO` | VARCHAR(15) | Estado del ciclo de vida de la venta | DEFAULT 'Pendiente'. Valores permitidos: Pendiente, Completada, Cancelada. Al pasar a Cancelada repone el stock automáticamente |
| `ID_USUARIO` | INT | Número identificador del cliente | Llave foránea -> USUARIO(ID_USUARIO) |

## DETALLE_VENTA

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_DETALLE_VENTA` | INT | Número identificador de la línea de venta | Llave primaria (detalle) |
| `CANTIDAD` | INT | Cantidad de unidades vendidas de ese producto | NOT NULL. CHECK: CANTIDAD > 0 |
| `PRECIO_UNITARIO` | DECIMAL(10,2) | Precio del producto congelado al momento de la venta | NOT NULL. Copia de Producto.Precio en el instante de la compra, no cambia si el precio del catálogo cambia después |
| `SUBTOTAL` | DECIMAL(10,2) | Resultado de CANTIDAD x PRECIO_UNITARIO | NOT NULL |
| `ID_VENTA` | INT | Número identificador de la venta a la que pertenece | Llave foránea -> VENTA(ID_VENTA) |
| `ID_PRODUCTO` | INT | Número identificador del producto vendido | Llave foránea -> PRODUCTO(ID_PRODUCTO). Dispara trigger de descuento de stock al insertarse |

## GARANTIA

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_GARANTIA` | INT | Número identificador de la solicitud de garantía | Llave primaria |
| `FECHA_SOLICITUD` | DATETIME | Fecha en que el cliente solicitó la garantía | DEFAULT GETDATE() |
| `MOTIVO` | VARCHAR(150) | Motivo breve del reclamo | Null permitido |
| `DESCRIPCION` | VARCHAR(300) | Descripción detallada del reclamo | Null permitido |
| `ESTADO` | VARCHAR(15) | Estado de la solicitud de garantía | DEFAULT 'En proceso'. Valores permitidos: En proceso, Aprobada, Rechazada |
| `FECHA_RESOLUCION` | DATETIME | Fecha en que el admin resolvió la solicitud | Null hasta que se resuelve (sin DEFAULT). Se completa automáticamente al cambiar ESTADO |
| `ID_DETALLE_VENTA` | INT | Línea de venta específica sobre la que se reclama | Llave foránea -> DETALLE_VENTA(ID_DETALLE_VENTA). Se valida que pertenezca al usuario solicitante |

## CARRITO

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_CARRITO` | INT | Número identificador del carrito | Llave primaria (cabecera) |
| `FECHA_CREACION` | DATETIME | Fecha en que se creó el carrito | DEFAULT GETDATE() |
| `ESTADO` | VARCHAR(15) | Estado del carrito | DEFAULT 'Activo'. Valores permitidos: Activo, Facturado. Pasa a Facturado al completar el checkout |
| `ID_USUARIO` | INT | Número identificador del cliente dueño del carrito | Llave foránea -> USUARIO(ID_USUARIO). Un usuario mantiene un solo carrito Activo a la vez |

## DETALLE_CARRITO

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_DETALLE_CARRITO` | INT | Número identificador de la línea de carrito | Llave primaria (detalle) |
| `CANTIDAD` | INT | Cantidad de unidades del producto en el carrito | NOT NULL. CHECK: CANTIDAD > 0 |
| `ID_CARRITO` | INT | Número identificador del carrito al que pertenece | Llave foránea -> CARRITO(ID_CARRITO) |
| `ID_PRODUCTO` | INT | Número identificador del producto agregado | Llave foránea -> PRODUCTO(ID_PRODUCTO). No almacena precio: se consulta el precio vigente al mostrar el carrito |

## COMPRA_PROVEEDOR

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_COMPRA` | INT | Número identificador de la orden de compra | Llave primaria (cabecera) |
| `FECHA_COMPRA` | DATETIME | Fecha en que se registró la orden de compra | DEFAULT GETDATE() |
| `TOTAL` | DECIMAL(10,2) | Total de la orden de compra | DEFAULT 0. Se acumula al agregar líneas de detalle |
| `ESTADO` | VARCHAR(15) | Estado de la orden de compra | DEFAULT 'Pendiente'. Valores permitidos: Pendiente, Recibida, Cancelada. Al pasar a Recibida dispara el aumento de stock |
| `ID_PROVEEDOR` | INT | Número identificador del proveedor | Llave foránea -> PROVEEDOR(ID_PROVEEDOR) |

## DETALLE_COMPRA

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_DETALLE_COMPRA` | INT | Número identificador de la línea de compra | Llave primaria (detalle) |
| `CANTIDAD` | INT | Cantidad de unidades pedidas de ese producto | NOT NULL. CHECK: CANTIDAD > 0 |
| `PRECIO_COMPRA` | DECIMAL(10,2) | Precio pagado al proveedor por unidad | NOT NULL |
| `SUBTOTAL` | DECIMAL(10,2) | Resultado de CANTIDAD x PRECIO_COMPRA | NOT NULL |
| `ID_COMPRA` | INT | Número identificador de la orden de compra | Llave foránea -> COMPRA_PROVEEDOR(ID_COMPRA) |
| `ID_PRODUCTO` | INT | Número identificador del producto pedido | Llave foránea -> PRODUCTO(ID_PRODUCTO) |

## HISTORIAL_INVENTARIO

| Field | Type | Description | Notes |
|---|---|---|---|
| `ID_MOVIMIENTO` | INT | Número identificador del movimiento | Llave primaria |
| `TIPO_MOVIMIENTO` | VARCHAR(10) | Dirección del movimiento de stock | NOT NULL. Valores permitidos: ENTRADA, SALIDA |
| `CANTIDAD` | INT | Cantidad de unidades del movimiento | NOT NULL |
| `FECHA` | DATETIME | Fecha del movimiento | DEFAULT GETDATE() |
| `OBSERVACION` | VARCHAR(200) | Detalle del origen del movimiento | Generado automáticamente por los triggers (ej. 'Salida por venta') |
| `ID_PRODUCTO` | INT | Número identificador del producto afectado | Llave foránea -> PRODUCTO(ID_PRODUCTO). Tabla alimentada únicamente por triggers, sin INSERT manual |
