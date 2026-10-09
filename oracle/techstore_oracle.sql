/* VERSIÓN ORIGINAL (Oracle PL/SQL) - SIN MANTENIMIENTO
 * La versión mantenida es la de SQL Server (carpeta /sqlserver).
 * Diferencias conocidas y arreglos que solo existen en SQL Server: ver
 * docs/oracle-to-sqlserver-migration.md
 * No se ha re-probado desde la migración. */

/* ========================== PROYECTO: Tienda de Productos Tecnológicos =========================== */

-- USER sys
-- Solo para desarrollo local. "_ORACLE_SCRIPT" permite crear un usuario común en
-- una instancia con CDB sin prefijo C##; no usar en un entorno real.
-- La contraseña se pide por sustitución (&&TIENDA_PASSWORD): no se guarda en el repo.

/* ================= Usuario (aquí viven diferentes roles) ================== */

ALTER SESSION SET "_ORACLE_SCRIPT" = true;
CREATE USER TIENDA
IDENTIFIED BY "&&TIENDA_PASSWORD"
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER TO TIENDA;

-- USER TIENDA

/* ============================= TABLAS ================================= */

/* ================= Tabla Rol ==================== */
CREATE TABLE ROL (
    ID_ROL      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE      VARCHAR2(30) NOT NULL,
    DESCRIPCION VARCHAR2(100)
);

/* ================= Tabla Categoria ==================== */
CREATE TABLE CATEGORIA (
    ID_CATEGORIA NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE       VARCHAR2(40) NOT NULL,
    DESCRIPCION  VARCHAR2(150)
);

/* ================= Tabla Marca ==================== */
CREATE TABLE MARCA (
    ID_MARCA     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE       VARCHAR2(40) NOT NULL,
    PAIS_ORIGEN  VARCHAR2(40)
);

/* ================= Tabla Proveedor ==================== */
CREATE TABLE PROVEEDOR (
    ID_PROVEEDOR NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE       VARCHAR2(60) NOT NULL,
    EMPRESA      VARCHAR2(60),
    TELEFONO     VARCHAR2(20),
    CORREO       VARCHAR2(80),
    SITIO_WEB    VARCHAR2(120)
);

/* ================= Tabla Usuario ==================== */
-- CORREO es UNIQUE porque el login autentica por correo + contraseña.
-- CONTRASENIA se almacena ya hasheada (el hash lo genera C#, no Oracle).
CREATE TABLE USUARIO (
    ID_USUARIO     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE         VARCHAR2(50) NOT NULL,
    APELLIDOS      VARCHAR2(50) NOT NULL,
    CORREO         VARCHAR2(80) NOT NULL,
    CONTRASENIA    VARCHAR2(200) NOT NULL,
    TELEFONO       VARCHAR2(20),
    FECHA_REGISTRO DATE DEFAULT SYSDATE NOT NULL,
    ESTADO         VARCHAR2(15) DEFAULT 'Activo' NOT NULL,
    ID_ROL         NUMBER NOT NULL,
    CONSTRAINT UQ_USUARIO_CORREO UNIQUE (CORREO),
    CONSTRAINT CK_USUARIO_ESTADO CHECK (ESTADO IN ('Activo','Inactivo')),
    CONSTRAINT FK_USUARIO_ROL FOREIGN KEY (ID_ROL) REFERENCES ROL(ID_ROL)
);

/* ================= Tabla Producto ==================== */
CREATE TABLE PRODUCTO (
    ID_PRODUCTO  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE       VARCHAR2(80) NOT NULL,
    DESCRIPCION  VARCHAR2(300),
    PRECIO       NUMBER(10,2) NOT NULL,
    STOCK        NUMBER DEFAULT 0 NOT NULL,
    STOCK_MIN    NUMBER DEFAULT 5 NOT NULL,
    ESTADO       VARCHAR2(15) DEFAULT 'Activo' NOT NULL,
    ID_CATEGORIA NUMBER NOT NULL,
    ID_MARCA     NUMBER NOT NULL,
    CONSTRAINT CK_PRODUCTO_ESTADO CHECK (ESTADO IN ('Activo','Inactivo')),
    CONSTRAINT CK_PRODUCTO_PRECIO CHECK (PRECIO >= 0),
    CONSTRAINT CK_PRODUCTO_STOCK CHECK (STOCK >= 0),
    CONSTRAINT FK_PRODUCTO_CATEGORIA FOREIGN KEY (ID_CATEGORIA) REFERENCES CATEGORIA(ID_CATEGORIA),
    CONSTRAINT FK_PRODUCTO_MARCA FOREIGN KEY (ID_MARCA) REFERENCES MARCA(ID_MARCA)
);

/* ================= Tabla Venta (header) ==================== */
CREATE TABLE VENTA (
    ID_VENTA       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    FECHA          DATE DEFAULT SYSDATE NOT NULL,
    IMPUESTO       NUMBER(10,2) DEFAULT 0,
    DESCUENTO      NUMBER(10,2) DEFAULT 0,
    TOTAL          NUMBER(10,2) DEFAULT 0,
    ESTADO         VARCHAR2(15) DEFAULT 'Pendiente' NOT NULL,
    ID_USUARIO     NUMBER NOT NULL,
    CONSTRAINT CK_VENTA_ESTADO CHECK (ESTADO IN ('Pendiente','Completada','Cancelada')),
    CONSTRAINT FK_VENTA_USUARIO FOREIGN KEY (ID_USUARIO) REFERENCES USUARIO(ID_USUARIO)
);

/* ================= Tabla Detalle_Venta (content) ==================== */
CREATE TABLE DETALLE_VENTA (
    ID_DETALLE_VENTA NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CANTIDAD         NUMBER NOT NULL,
    PRECIO_UNITARIO  NUMBER(10,2) NOT NULL,
    SUBTOTAL         NUMBER(10,2) NOT NULL,
    ID_VENTA         NUMBER NOT NULL,
    ID_PRODUCTO      NUMBER NOT NULL,
    CONSTRAINT CK_DETVENTA_CANTIDAD CHECK (CANTIDAD > 0),
    CONSTRAINT FK_DETVENTA_VENTA FOREIGN KEY (ID_VENTA) REFERENCES VENTA(ID_VENTA),
    CONSTRAINT FK_DETVENTA_PRODUCTO FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTO(ID_PRODUCTO)
);

/* ================= Tabla Garantia ==================== */
-- Se asocia a la línea de detalle de venta, no a la venta completa
-- (una garantía es sobre un producto específico comprado).
CREATE TABLE GARANTIA (
    ID_GARANTIA       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    FECHA_SOLICITUD   DATE DEFAULT SYSDATE NOT NULL,
    MOTIVO            VARCHAR2(150),
    DESCRIPCION       VARCHAR2(300),
    ESTADO            VARCHAR2(15) DEFAULT 'En proceso' NOT NULL,
    FECHA_RESOLUCION  DATE,
    ID_DETALLE_VENTA  NUMBER NOT NULL,
    CONSTRAINT CK_GARANTIA_ESTADO CHECK (ESTADO IN ('En proceso','Aprobada','Rechazada')),
    CONSTRAINT FK_GARANTIA_DETVENTA FOREIGN KEY (ID_DETALLE_VENTA) REFERENCES DETALLE_VENTA(ID_DETALLE_VENTA)
);

/* ================= Tabla Carrito ==================== */
CREATE TABLE CARRITO (
    ID_CARRITO     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    FECHA_CREACION DATE DEFAULT SYSDATE NOT NULL,
    ESTADO         VARCHAR2(15) DEFAULT 'Activo' NOT NULL,
    ID_USUARIO     NUMBER NOT NULL,
    CONSTRAINT CK_CARRITO_ESTADO CHECK (ESTADO IN ('Activo','Facturado')),
    CONSTRAINT FK_CARRITO_USUARIO FOREIGN KEY (ID_USUARIO) REFERENCES USUARIO(ID_USUARIO)
);

/* ================= Tabla Detalle_Carrito ==================== */
CREATE TABLE DETALLE_CARRITO (
    ID_DETALLE_CARRITO NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CANTIDAD            NUMBER NOT NULL,
    ID_CARRITO          NUMBER NOT NULL,
    ID_PRODUCTO         NUMBER NOT NULL,
    CONSTRAINT CK_DETCARRITO_CANTIDAD CHECK (CANTIDAD > 0),
    CONSTRAINT FK_DETCARRITO_CARRITO FOREIGN KEY (ID_CARRITO) REFERENCES CARRITO(ID_CARRITO),
    CONSTRAINT FK_DETCARRITO_PRODUCTO FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTO(ID_PRODUCTO)
);

/* ================= Tabla Compra_Proveedor (cabecera) ==================== */
CREATE TABLE COMPRA_PROVEEDOR (
    ID_COMPRA     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    FECHA_COMPRA  DATE DEFAULT SYSDATE NOT NULL,
    TOTAL         NUMBER(10,2) DEFAULT 0,
    ESTADO        VARCHAR2(15) DEFAULT 'Pendiente' NOT NULL,
    ID_PROVEEDOR  NUMBER NOT NULL,
    CONSTRAINT CK_COMPRA_ESTADO CHECK (ESTADO IN ('Pendiente','Recibida','Cancelada')),
    CONSTRAINT FK_COMPRA_PROVEEDOR FOREIGN KEY (ID_PROVEEDOR) REFERENCES PROVEEDOR(ID_PROVEEDOR)
);

/* ================= Tabla Detalle_Compra (líneas) ==================== */
CREATE TABLE DETALLE_COMPRA (
    ID_DETALLE_COMPRA NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CANTIDAD          NUMBER NOT NULL,
    PRECIO_COMPRA     NUMBER(10,2) NOT NULL,
    SUBTOTAL          NUMBER(10,2) NOT NULL,
    ID_COMPRA         NUMBER NOT NULL,
    ID_PRODUCTO       NUMBER NOT NULL,
    CONSTRAINT CK_DETCOMPRA_CANTIDAD CHECK (CANTIDAD > 0),
    CONSTRAINT FK_DETCOMPRA_COMPRA FOREIGN KEY (ID_COMPRA) REFERENCES COMPRA_PROVEEDOR(ID_COMPRA),
    CONSTRAINT FK_DETCOMPRA_PRODUCTO FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTO(ID_PRODUCTO)
);

/* ================= Tabla Historial_Inventario (triggers) ==================== */

CREATE TABLE HISTORIAL_INVENTARIO (
    ID_MOVIMIENTO   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    TIPO_MOVIMIENTO VARCHAR2(10) NOT NULL,
    CANTIDAD        NUMBER NOT NULL,
    FECHA           DATE DEFAULT SYSDATE NOT NULL,
    OBSERVACION     VARCHAR2(200),
    ID_PRODUCTO     NUMBER NOT NULL,
    CONSTRAINT CK_HIST_TIPO CHECK (TIPO_MOVIMIENTO IN ('ENTRADA','SALIDA')),
    CONSTRAINT FK_HIST_PRODUCTO FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTO(ID_PRODUCTO)
);


/* ================= Procedimientos (DML) ==================== */

-- //////////// USUARIO ///////////// --

/* ================= INSERT (Usuario) ==================== */
CREATE OR REPLACE PROCEDURE NEW_USUARIO(
    p_NOMBRE      VARCHAR2,
    p_APELLIDOS   VARCHAR2,
    p_CORREO      VARCHAR2,
    p_CONTRASENIA VARCHAR2,
    p_TELEFONO    VARCHAR2,
    p_ID_ROL      NUMBER)
AS
    BEGIN
        INSERT INTO USUARIO (NOMBRE, APELLIDOS, CORREO, CONTRASENIA, TELEFONO, ID_ROL)
        VALUES (p_NOMBRE, p_APELLIDOS, p_CORREO, p_CONTRASENIA, p_TELEFONO, p_ID_ROL);
        COMMIT;
    END NEW_USUARIO;
/

/* ================= UPDATE (Usuario) ==================== */
CREATE OR REPLACE PROCEDURE UPD_USUARIO(
    p_ID_USUARIO NUMBER,
    p_NOMBRE     VARCHAR2,
    p_APELLIDOS  VARCHAR2,
    p_TELEFONO   VARCHAR2)
AS
    BEGIN
        UPDATE USUARIO
        SET NOMBRE = p_NOMBRE,
            APELLIDOS = p_APELLIDOS,
            TELEFONO = p_TELEFONO
        WHERE ID_USUARIO = p_ID_USUARIO;
        COMMIT;
    END UPD_USUARIO;
/

/* ================= DELETE (Usuario) ==================== */
CREATE OR REPLACE PROCEDURE DEL_USUARIO(p_ID_USUARIO NUMBER) AS
    v_TIENE_VENTAS NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_TIENE_VENTAS
        FROM VENTA
        WHERE ID_USUARIO = p_ID_USUARIO;

        IF v_TIENE_VENTAS > 0 THEN
            -- Tiene historial real de compras: se preserva, solo se inactiva
            UPDATE USUARIO
            SET ESTADO = 'Inactivo'
            WHERE ID_USUARIO = p_ID_USUARIO;
        ELSE
            -- Sin ventas: limpia carritos sueltos y borra físicamente
            DELETE FROM DETALLE_CARRITO
            WHERE ID_CARRITO IN (SELECT ID_CARRITO FROM CARRITO WHERE ID_USUARIO = p_ID_USUARIO);

            DELETE FROM CARRITO
            WHERE ID_USUARIO = p_ID_USUARIO;

            DELETE FROM USUARIO
            WHERE ID_USUARIO = p_ID_USUARIO;
        END IF;

        COMMIT;
    END DEL_USUARIO;
/

-- //////////// PRODUCTO ///////////// --

/* ================= INSERT (Producto) ==================== */
CREATE OR REPLACE PROCEDURE NEW_PRODUCTO(
    p_NOMBRE       VARCHAR2,
    p_DESCRIPCION  VARCHAR2,
    p_PRECIO       NUMBER,
    p_STOCK        NUMBER,
    p_STOCK_MIN    NUMBER,
    p_ID_CATEGORIA NUMBER,
    p_ID_MARCA     NUMBER)
AS
    BEGIN
        INSERT INTO PRODUCTO (NOMBRE, DESCRIPCION, PRECIO, STOCK, STOCK_MIN, ID_CATEGORIA, ID_MARCA)
        VALUES (p_NOMBRE, p_DESCRIPCION, p_PRECIO, p_STOCK, p_STOCK_MIN, p_ID_CATEGORIA, p_ID_MARCA);
        COMMIT;
    END NEW_PRODUCTO;
/

/* ================= UPDATE (Producto) ==================== */
-- Con p_ESTADO, el admin puede activar/desactivar un producto
CREATE OR REPLACE PROCEDURE UPD_PRODUCTO(
    p_ID_PRODUCTO NUMBER,
    p_NOMBRE      VARCHAR2,
    p_DESCRIPCION VARCHAR2,
    p_PRECIO      NUMBER,
    p_STOCK_MIN   NUMBER,
    p_ESTADO      VARCHAR2)
AS
    BEGIN
        UPDATE PRODUCTO
        SET NOMBRE = p_NOMBRE,
            DESCRIPCION = p_DESCRIPCION,
            PRECIO = p_PRECIO,
            STOCK_MIN = p_STOCK_MIN,
            ESTADO = p_ESTADO
        WHERE ID_PRODUCTO = p_ID_PRODUCTO;
        COMMIT;
    END UPD_PRODUCTO;
/

/* ================= DELETE (Producto) ==================== */
CREATE OR REPLACE PROCEDURE DEL_PRODUCTO(p_ID_PRODUCTO NUMBER) AS
    v_TIENE_HISTORIAL NUMBER;
    BEGIN
        SELECT
            (SELECT COUNT(*) FROM DETALLE_VENTA WHERE ID_PRODUCTO = p_ID_PRODUCTO) +
            (SELECT COUNT(*) FROM DETALLE_COMPRA WHERE ID_PRODUCTO = p_ID_PRODUCTO) +
            (SELECT COUNT(*) FROM HISTORIAL_INVENTARIO WHERE ID_PRODUCTO = p_ID_PRODUCTO)
        INTO v_TIENE_HISTORIAL
        FROM DUAL;

        IF v_TIENE_HISTORIAL > 0 THEN
            -- Tiene historial real: se preserva, solo se inactiva
            UPDATE PRODUCTO
            SET ESTADO = 'Inactivo'
            WHERE ID_PRODUCTO = p_ID_PRODUCTO;
        ELSE
            -- Sin historial: limpia carritos sueltos y borra físicamente
            DELETE FROM DETALLE_CARRITO
            WHERE ID_PRODUCTO = p_ID_PRODUCTO;

            DELETE FROM PRODUCTO
            WHERE ID_PRODUCTO = p_ID_PRODUCTO;
        END IF;

        COMMIT;
    END DEL_PRODUCTO;
/

-- //////////// VENTA (cabecera + detalle) ///////////// --

/* ================= INSERT Cabecera (Venta) ==================== */
-- OUT y RETURNING INTO para poder tomar la PK en una variable, utilizable en detalle
CREATE OR REPLACE PROCEDURE NEW_VENTA(
    p_ID_USUARIO NUMBER,
    p_IMPUESTO   NUMBER,
    p_DESCUENTO  NUMBER,
    p_ID_VENTA   OUT NUMBER)
AS
    BEGIN
        INSERT INTO VENTA (IMPUESTO, DESCUENTO, ID_USUARIO)
        VALUES (p_IMPUESTO, p_DESCUENTO, p_ID_USUARIO)
        RETURNING ID_VENTA INTO p_ID_VENTA;
        COMMIT;
    END NEW_VENTA;
/

/* ================= INSERT Detalle (Detalle_Venta) ==================== */
CREATE OR REPLACE PROCEDURE NEW_DETALLE_VENTA(
    p_ID_VENTA        NUMBER,
    p_ID_PRODUCTO     NUMBER,
    p_CANTIDAD        NUMBER,
    p_PRECIO_UNITARIO NUMBER)
AS
    BEGIN
        -- Se dispara el trigger
        INSERT INTO DETALLE_VENTA (CANTIDAD, PRECIO_UNITARIO, SUBTOTAL, ID_VENTA, ID_PRODUCTO)
        VALUES (p_CANTIDAD, p_PRECIO_UNITARIO, p_CANTIDAD * p_PRECIO_UNITARIO, p_ID_VENTA, p_ID_PRODUCTO);

        UPDATE VENTA v
        SET TOTAL = (
                SELECT NVL(SUM(dv.SUBTOTAL), 0) -- Validación NULL = 0
                FROM DETALLE_VENTA dv
                WHERE dv.ID_VENTA = v.ID_VENTA
            ) + v.IMPUESTO - v.DESCUENTO
        WHERE v.ID_VENTA = p_ID_VENTA;

        COMMIT;
    END NEW_DETALLE_VENTA;
/

/* ================= UPDATE Estado (Venta) ==================== */
CREATE OR REPLACE PROCEDURE UPD_ESTADO_VENTA(
    p_ID_VENTA NUMBER,
    p_ESTADO   VARCHAR2)
AS
    BEGIN
        UPDATE VENTA
        SET ESTADO = p_ESTADO
        WHERE ID_VENTA = p_ID_VENTA;
        COMMIT;
    END UPD_ESTADO_VENTA;
/

-- //////////// CARRITO (cabecera + detalle) ///////////// --

/* ================= INSERT Cabecera (Carrito) ==================== */
CREATE OR REPLACE PROCEDURE NEW_CARRITO(
    p_ID_USUARIO NUMBER,
    p_ID_CARRITO OUT NUMBER)
AS
    BEGIN
        INSERT INTO CARRITO (ID_USUARIO)
        VALUES (p_ID_USUARIO)
        RETURNING ID_CARRITO INTO p_ID_CARRITO;
        COMMIT;
    END NEW_CARRITO;
/

/* ================= INSERT Detalle (Detalle_Carrito) ==================== */
CREATE OR REPLACE PROCEDURE NEW_DETALLE_CARRITO(
    p_ID_CARRITO  NUMBER,
    p_ID_PRODUCTO NUMBER,
    p_CANTIDAD    NUMBER)
AS
    BEGIN
        INSERT INTO DETALLE_CARRITO (CANTIDAD, ID_CARRITO, ID_PRODUCTO)
        VALUES (p_CANTIDAD, p_ID_CARRITO, p_ID_PRODUCTO);
        COMMIT;
    END NEW_DETALLE_CARRITO;
/

/* ================= UPDATE Cantidad (Detalle_Carrito) ==================== */
CREATE OR REPLACE PROCEDURE UPD_CANTIDAD_DETALLE_CARRITO(
    p_ID_DETALLE_CARRITO NUMBER,
    p_CANTIDAD            NUMBER)
AS
    BEGIN
        UPDATE DETALLE_CARRITO
        SET CANTIDAD = p_CANTIDAD
        WHERE ID_DETALLE_CARRITO = p_ID_DETALLE_CARRITO;
        COMMIT;
    END UPD_CANTIDAD_DETALLE_CARRITO;
/

/* ================= UPDATE Estado (Carrito) ==================== */
CREATE OR REPLACE PROCEDURE UPD_ESTADO_CARRITO(
    p_ID_CARRITO NUMBER,
    p_ESTADO     VARCHAR2)
AS
    BEGIN
        UPDATE CARRITO
        SET ESTADO = p_ESTADO
        WHERE ID_CARRITO = p_ID_CARRITO;
        COMMIT;
    END UPD_ESTADO_CARRITO;
/

/* ================= DELETE Detalle (Detalle_Carrito) ==================== */
CREATE OR REPLACE PROCEDURE DEL_DETALLE_CARRITO(p_ID_DETALLE_CARRITO NUMBER) AS
    BEGIN
        DELETE FROM DETALLE_CARRITO
        WHERE ID_DETALLE_CARRITO = p_ID_DETALLE_CARRITO;
        COMMIT;
    END DEL_DETALLE_CARRITO;
/


-- //////////// COMPRA_PROVEEDOR (cabecera + detalle) ///////////// --

/* ================= INSERT Cabecera (Compra_Proveedor) ==================== */
CREATE OR REPLACE PROCEDURE NEW_COMPRA_PROVEEDOR(
    p_ID_PROVEEDOR NUMBER,
    p_ID_COMPRA    OUT NUMBER)
AS
    BEGIN
        INSERT INTO COMPRA_PROVEEDOR (ID_PROVEEDOR)
        VALUES (p_ID_PROVEEDOR)
        RETURNING ID_COMPRA INTO p_ID_COMPRA;
        COMMIT;
    END NEW_COMPRA_PROVEEDOR;
/

/* ================= INSERT Detalle (Detalle_Compra) ==================== */
CREATE OR REPLACE PROCEDURE NEW_DETALLE_COMPRA(
    p_ID_COMPRA    NUMBER,
    p_ID_PRODUCTO  NUMBER,
    p_CANTIDAD     NUMBER,
    p_PRECIO_COMPRA NUMBER)
AS
    BEGIN
        INSERT INTO DETALLE_COMPRA (CANTIDAD, PRECIO_COMPRA, SUBTOTAL, ID_COMPRA, ID_PRODUCTO)
        VALUES (p_CANTIDAD, p_PRECIO_COMPRA, p_CANTIDAD * p_PRECIO_COMPRA, p_ID_COMPRA, p_ID_PRODUCTO);

        UPDATE COMPRA_PROVEEDOR
        SET TOTAL = TOTAL + (p_CANTIDAD * p_PRECIO_COMPRA)
        WHERE ID_COMPRA = p_ID_COMPRA;

        COMMIT;
    END NEW_DETALLE_COMPRA;
/

/* ================= UPDATE Estado (Compra_Proveedor) ==================== */
-- Se dispara el trigger ('Recibida')
CREATE OR REPLACE PROCEDURE UPD_ESTADO_COMPRA(
    p_ID_COMPRA NUMBER,
    p_ESTADO    VARCHAR2)
AS
    BEGIN
        UPDATE COMPRA_PROVEEDOR
        SET ESTADO = p_ESTADO
        WHERE ID_COMPRA = p_ID_COMPRA;
        COMMIT;
    END UPD_ESTADO_COMPRA;
/

-- //////////// GARANTIA ///////////// --

/* ================= INSERT (Garantia) ==================== */
CREATE OR REPLACE PROCEDURE NEW_GARANTIA(
    p_ID_DETALLE_VENTA NUMBER,
    p_ID_USUARIO       NUMBER,
    p_MOTIVO           VARCHAR2,
    p_DESCRIPCION      VARCHAR2)
AS
    v_PERTENECE NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_PERTENECE
        FROM DETALLE_VENTA dv
        JOIN VENTA v ON v.ID_VENTA = dv.ID_VENTA
        WHERE dv.ID_DETALLE_VENTA = p_ID_DETALLE_VENTA
        AND v.ID_USUARIO = p_ID_USUARIO;

        --Ya sea que no se encontró la venta, o la venta no pertenece a este usuario
        IF v_PERTENECE = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Esta compra no pertenece al usuario solicitante');
        END IF;

        INSERT INTO GARANTIA (MOTIVO, DESCRIPCION, ID_DETALLE_VENTA)
        VALUES (p_MOTIVO, p_DESCRIPCION, p_ID_DETALLE_VENTA);

        COMMIT;
    END NEW_GARANTIA;
/

/* ================= UPDATE Estado (Garantia) ==================== */
CREATE OR REPLACE PROCEDURE UPD_ESTADO_GARANTIA(
    p_ID_GARANTIA NUMBER,
    p_ESTADO      VARCHAR2)
AS
    BEGIN
        UPDATE GARANTIA
        SET ESTADO = p_ESTADO,
            FECHA_RESOLUCION = SYSDATE
        WHERE ID_GARANTIA = p_ID_GARANTIA;
        COMMIT;
    END UPD_ESTADO_GARANTIA;
/


/* ============================== BLOQUE 3: FUNCIONES (idea de negocio) ============================= */

/* ================= Productos con stock bajo mínimo (FUNCTION) ==================== */
CREATE OR REPLACE FUNCTION FN_PRODUCTOS_STOCK_BAJO
    RETURN NUMBER IS
    vCANTIDAD NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO vCANTIDAD
        FROM PRODUCTO
        WHERE STOCK <= STOCK_MIN
        AND ESTADO = 'Activo';
        RETURN vCANTIDAD;
    END FN_PRODUCTOS_STOCK_BAJO;
/

/* ================= Total gastado por usuario (FUNCTION) ==================== */
CREATE OR REPLACE FUNCTION FN_TOTAL_GASTADO_USUARIO(p_ID_USUARIO NUMBER)
    RETURN NUMBER IS
    vTOTAL NUMBER;
    BEGIN
        SELECT NVL(SUM(TOTAL), 0)
        INTO vTOTAL
        FROM VENTA
        WHERE ID_USUARIO = p_ID_USUARIO
        AND ESTADO = 'Completada';
        RETURN vTOTAL;
    END FN_TOTAL_GASTADO_USUARIO;
/

/* ================= Producto más vendido (FUNCTION) ==================== */
CREATE OR REPLACE FUNCTION FN_PRODUCTO_MAS_VENDIDO
    RETURN VARCHAR2 IS
    vNOMBRE VARCHAR2(80);
    BEGIN
        SELECT NOMBRE INTO vNOMBRE
        FROM (
            SELECT p.NOMBRE, SUM(dv.CANTIDAD) AS TOTAL_VENDIDO
            FROM DETALLE_VENTA dv
            JOIN PRODUCTO p ON p.ID_PRODUCTO = dv.ID_PRODUCTO
            GROUP BY p.NOMBRE
            ORDER BY TOTAL_VENDIDO DESC
        )
        WHERE ROWNUM = 1;
        RETURN vNOMBRE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Sin ventas registradas';
    END FN_PRODUCTO_MAS_VENDIDO;
/

/* ================= Vigencia de garantía (FUNCTION) ==================== */
-- Calcula si una garantía sigue vigente, considerando una ventana de
-- 30 días desde la fecha de la venta asociada al detalle de venta.

CREATE OR REPLACE FUNCTION FN_GARANTIA_VIGENTE(p_ID_DETALLE_VENTA NUMBER)
    RETURN VARCHAR2 IS
    vFECHA_VENTA DATE;
    BEGIN
        SELECT v.FECHA INTO vFECHA_VENTA
        FROM VENTA v
        JOIN DETALLE_VENTA dv ON dv.ID_VENTA = v.ID_VENTA
        WHERE dv.ID_DETALLE_VENTA = p_ID_DETALLE_VENTA;

        IF SYSDATE - vFECHA_VENTA <= 30 THEN -- Resta de fechas se da resultado NUMBER de días
            RETURN 'Vigente';
        ELSE
            RETURN 'Vencida';
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'No aplica';
    END FN_GARANTIA_VIGENTE;
/


/* ====================================== BLOQUE 4: TRIGGERS ====================================== */

/* ================= Control de stock por Venta (TRIGGER) ==================== */
-- Al insertar una línea en Detalle_Venta: valida stock disponible,
-- descuenta stock en Producto y registra la salida en Historial_Inventario.

CREATE OR REPLACE TRIGGER TRIG_STOCK_VENTA
    BEFORE INSERT ON DETALLE_VENTA
    FOR EACH ROW
    DECLARE
    vSTOCK_ACTUAL NUMBER;

    BEGIN
        SELECT STOCK INTO vSTOCK_ACTUAL
        FROM PRODUCTO
        WHERE ID_PRODUCTO = :NEW.ID_PRODUCTO;

        IF vSTOCK_ACTUAL < :NEW.CANTIDAD THEN
            RAISE_APPLICATION_ERROR(-20001, 'Stock insuficiente para el producto seleccionado');
        END IF;

        UPDATE PRODUCTO
        SET STOCK = STOCK - :NEW.CANTIDAD
        WHERE ID_PRODUCTO = :NEW.ID_PRODUCTO;

        INSERT INTO HISTORIAL_INVENTARIO (TIPO_MOVIMIENTO, CANTIDAD, OBSERVACION, ID_PRODUCTO)
        VALUES ('SALIDA', :NEW.CANTIDAD, 'Salida por venta', :NEW.ID_PRODUCTO);
    END;
/

/* ================= Control de stock por Compra RECIBIDA (TRIGGER) ==================== */
-- Cuando el admin marca la orden como 'Recibida' recorre todas las
-- líneas de Detalle_Compra de esa orden y aumenta el stock

CREATE OR REPLACE TRIGGER TRIG_STOCK_COMPRA
    AFTER UPDATE OF ESTADO ON COMPRA_PROVEEDOR
    FOR EACH ROW
    WHEN (NEW.ESTADO = 'Recibida' AND OLD.ESTADO != 'Recibida')
    BEGIN
        FOR fila IN (
            SELECT ID_PRODUCTO, CANTIDAD
            FROM DETALLE_COMPRA
            WHERE ID_COMPRA = :NEW.ID_COMPRA
        ) LOOP
            UPDATE PRODUCTO
            SET STOCK = STOCK + fila.CANTIDAD
            WHERE ID_PRODUCTO = fila.ID_PRODUCTO;

            INSERT INTO HISTORIAL_INVENTARIO (TIPO_MOVIMIENTO, CANTIDAD, OBSERVACION, ID_PRODUCTO)
            VALUES ('ENTRADA', fila.CANTIDAD, 'Entrada por compra a proveedor recibida', fila.ID_PRODUCTO);
        END LOOP;
    END;
/

/* ================= Reposición de stock por Venta cancelada (TRIGGER) ==================== */
-- Cuando cambia el estado a 'Cancelada' recorre todas las
-- líneas de Detalle_Venta de esa venta, devuelve el stock a Producto y 
-- deja constancia del reingreso en Historial_Inventario.

CREATE OR REPLACE TRIGGER TRIG_REPOSICION_VENTA_CANCELADA
    AFTER UPDATE OF ESTADO ON VENTA
    FOR EACH ROW
    WHEN (NEW.ESTADO = 'Cancelada' AND OLD.ESTADO != 'Cancelada')
    BEGIN
        FOR fila IN (
            SELECT ID_PRODUCTO, CANTIDAD
            FROM DETALLE_VENTA
            WHERE ID_VENTA = :NEW.ID_VENTA
        ) LOOP
            UPDATE PRODUCTO
            SET STOCK = STOCK + fila.CANTIDAD
            WHERE ID_PRODUCTO = fila.ID_PRODUCTO;

            INSERT INTO HISTORIAL_INVENTARIO (TIPO_MOVIMIENTO, CANTIDAD, OBSERVACION, ID_PRODUCTO)
            VALUES ('ENTRADA', fila.CANTIDAD, 'Reingreso por cancelación de venta', fila.ID_PRODUCTO);
        END LOOP;
    END;
/


/* =================================== BLOQUE 5: ÍNDICES ======================================= */

/* ================= Índice de búsqueda por nombre de producto ==================== */
-- Justificación de negocio: la barra de búsqueda de la tienda (vista
-- cliente) filtra productos por nombre constantemente; este índice
-- acelera esas búsquedas.
CREATE INDEX IDX_PRODUCTO_NOMBRE
ON PRODUCTO(NOMBRE);

/* ================= Índices de búsqueda en tablas de detalle ==================== */
-- Las FK no se indexan automáticamente en Oracle (a diferencia de la PK).
-- Estas tablas crecen constantemente y casi toda consulta/trigger las
-- filtra por su columna FK hacia la cabecera, así que el índice acelera
-- esas búsquedas a medida que el volumen de datos aumenta.

CREATE INDEX IDX_DETVENTA_ID_VENTA ON DETALLE_VENTA(ID_VENTA);

CREATE INDEX IDX_DETCOMPRA_ID_COMPRA ON DETALLE_COMPRA(ID_COMPRA);

CREATE INDEX IDX_DETCARRITO_ID_CARRITO ON DETALLE_CARRITO(ID_CARRITO);


/* ==================================== BLOQUE 6: VISTAS ============================================= */

/* ================= Vista: Productos con stock bajo mínimo ==================== */
CREATE OR REPLACE VIEW VIS_STOCK_BAJO AS
    SELECT
        p.ID_PRODUCTO,
        p.NOMBRE,
        p.STOCK,
        p.STOCK_MIN,
        c.NOMBRE AS CATEGORIA,
        m.NOMBRE AS MARCA
    FROM PRODUCTO p
    JOIN CATEGORIA c ON c.ID_CATEGORIA = p.ID_CATEGORIA
    JOIN MARCA m ON m.ID_MARCA = p.ID_MARCA
    WHERE p.STOCK <= p.STOCK_MIN
    AND p.ESTADO = 'Activo'
    ORDER BY p.STOCK ASC;
/

/* ================= Vista: Detalle completo de ventas ==================== */
CREATE OR REPLACE VIEW VIS_VENTAS_DETALLE AS
    SELECT
        v.ID_VENTA,
        u.NOMBRE || ' ' || u.APELLIDOS AS CLIENTE,
        v.FECHA,
        p.NOMBRE AS PRODUCTO,
        dv.CANTIDAD,
        dv.PRECIO_UNITARIO,
        dv.SUBTOTAL,
        v.IMPUESTO,
        v.DESCUENTO,
        v.TOTAL,
        v.ESTADO
    FROM VENTA v
    JOIN USUARIO u ON u.ID_USUARIO = v.ID_USUARIO
    JOIN DETALLE_VENTA dv ON dv.ID_VENTA = v.ID_VENTA
    JOIN PRODUCTO p ON p.ID_PRODUCTO = dv.ID_PRODUCTO
    ORDER BY v.FECHA DESC;
/

/* ================= Vista: Historial de movimientos de inventario ==================== */
CREATE OR REPLACE VIEW VIS_HISTORIAL_INVENTARIO AS
    SELECT
        h.ID_MOVIMIENTO,
        p.NOMBRE AS PRODUCTO,
        h.TIPO_MOVIMIENTO,
        h.CANTIDAD,
        h.FECHA,
        h.OBSERVACION
    FROM HISTORIAL_INVENTARIO h
    JOIN PRODUCTO p ON p.ID_PRODUCTO = h.ID_PRODUCTO
    ORDER BY h.FECHA DESC;
/


/* ================================== BLOQUE 7: DATOS BASE ===================================== */

-- Catálogo mínimo de arranque (roles para el login, y
-- categoría/marca para poblar combos del formulario de productos).
-- El resto de los datos (usuarios, productos, ventas, carritos,
-- compras) se generan y se validan desde la aplicación web, no aquí.

INSERT INTO ROL (NOMBRE, DESCRIPCION) VALUES ('Administrador', 'Acceso completo al sistema');
INSERT INTO ROL (NOMBRE, DESCRIPCION) VALUES ('Cliente', 'Usuario comprador de la tienda');

INSERT INTO CATEGORIA (NOMBRE, DESCRIPCION) VALUES ('Laptops', 'Computadoras portátiles');
INSERT INTO CATEGORIA (NOMBRE, DESCRIPCION) VALUES ('Accesorios', 'Periféricos y accesorios tecnológicos');

INSERT INTO MARCA (NOMBRE, PAIS_ORIGEN) VALUES ('Dell', 'Estados Unidos');
INSERT INTO MARCA (NOMBRE, PAIS_ORIGEN) VALUES ('Logitech', 'Suiza');

COMMIT;
