-- ========== CATEGORIA ==========
CREATE TABLE Categoria (
  categoria_id NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre       VARCHAR2(80) NOT NULL
);

-- ========== CLIENTE ==========
CREATE TABLE Cliente (
  cliente_id NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre     VARCHAR2(120) NOT NULL,
  email      VARCHAR2(160) NOT NULL,
  telefono   VARCHAR2(30),
  direccion  VARCHAR2(240),
  creado_en  DATE NOT NULL,
  estado     VARCHAR2(20) NOT NULL
);

-- ========== PRODUCTO ==========
CREATE TABLE Producto (
  producto_id  NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku          VARCHAR2(40)  NOT NULL,
  nombre       VARCHAR2(160) NOT NULL,
  descripcion  VARCHAR2(400),
  precio_unit  NUMBER(10,2)  NOT NULL,
  stock_actual NUMBER(10)    NOT NULL,
  categoria_id NUMBER(10)    NOT NULL,
  activo       NUMBER(10),
  CONSTRAINT fk_prod_categoria
    FOREIGN KEY (categoria_id) REFERENCES Categoria(categoria_id)
);
CREATE UNIQUE INDEX uq_producto_sku ON Producto(sku);
CREATE INDEX idx_prod_categoria ON Producto(categoria_id);

-- ========== PEDIDO ==========
CREATE TABLE Pedido (
  pedido_id    NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cliente_id   NUMBER(10)   NOT NULL,
  fecha_pedido DATE         NOT NULL,
  estado       VARCHAR2(20) NOT NULL,
  total_bruto  NUMBER(12,2) NOT NULL,
  total_desc   NUMBER(12,2) NOT NULL,
  total_neto   NUMBER(12,2) NOT NULL,
  CONSTRAINT fk_pedido_cliente
    FOREIGN KEY (cliente_id) REFERENCES Cliente(cliente_id)
);

-- ========== PEDIDO_DET ==========
CREATE TABLE Pedido_Det (
  pedido_det_id NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pedido_id     NUMBER(10)   NOT NULL,
  producto_id   NUMBER(10)   NOT NULL,
  cantidad      NUMBER(10)   NOT NULL,
  precio_unit   NUMBER(10,2) NOT NULL,
  total         NUMBER(12,2) NOT NULL,
  CONSTRAINT fk_det_pedido
    FOREIGN KEY (pedido_id)   REFERENCES Pedido(pedido_id),
  CONSTRAINT fk_det_producto
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id)
);
CREATE INDEX idx_det_pedido ON Pedido_Det(pedido_id);
CREATE INDEX idx_det_prod   ON Pedido_Det(producto_id);

-- ========== PAGO ==========
CREATE TABLE Pago (
  pago_id    NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pedido_id  NUMBER(10)   NOT NULL,
  metodo     VARCHAR2(30),
  monto      NUMBER(12,2) NOT NULL,
  fecha_pago DATE         NOT NULL,
  estado     VARCHAR2(20),
  CONSTRAINT fk_pago_pedido
    FOREIGN KEY (pedido_id) REFERENCES Pedido(pedido_id)
);
CREATE INDEX idx_pago_pedido ON Pago(pedido_id);

-- ========== ENVIO ==========
CREATE TABLE Envio (
  envio_id        NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pedido_id       NUMBER(10)    NOT NULL,
  direccion_envio VARCHAR2(240) NOT NULL,
  empresa         VARCHAR2(80),
  guia            VARCHAR2(80),
  fecha_envio     DATE,
  fecha_entrega   DATE,
  estado          VARCHAR2(20),
  CONSTRAINT fk_envio_pedido
    FOREIGN KEY (pedido_id) REFERENCES Pedido(pedido_id)
);
CREATE INDEX idx_envio_pedido ON Envio(pedido_id);

-- ========== INVENTARIO_MOV ==========
CREATE TABLE Inventario_Mov (
  mov_id      NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  producto_id NUMBER(10)   NOT NULL,
  tipo        VARCHAR2(30) NOT NULL,
  cantidad    NUMBER(10)   NOT NULL,
  motivo      VARCHAR2(120),
  creado_en   DATE         NOT NULL,
  CONSTRAINT fk_mov_producto
    FOREIGN KEY (producto_id) REFERENCES Producto(producto_id)
);
CREATE INDEX idx_mov_producto ON Inventario_Mov(producto_id);

SELECT table_name FROM user_tables ORDER BY table_name;



/* =========================================================
	(FUNCION + CRUD + TRIGGERS)
	Tablas objetivo: Categorias, clientes, productos, envios e inventario
	========================================================= */

/* =========================================================
   PAQUETE: pkg_categoria
   Gestiona el catálogo de categorías de producto
   ========================================================= */
CREATE OR REPLACE PACKAGE pkg_categoria AS
  PROCEDURE sp_categoria_create (
    p_nombre     IN  VARCHAR2,
    o_categoria_id OUT NUMBER
  );

  PROCEDURE sp_categoria_get_by_id (
    p_categoria_id IN NUMBER,
    o_cursor       OUT SYS_REFCURSOR
  );

  PROCEDURE sp_categoria_list (
    o_cursor OUT SYS_REFCURSOR
  );

  PROCEDURE sp_categoria_update (
    p_categoria_id IN NUMBER,
    p_nombre       IN VARCHAR2
  );

  PROCEDURE sp_categoria_delete (
    p_categoria_id IN NUMBER
  );
END pkg_categoria;
/
SHOW ERRORS


CREATE OR REPLACE PACKAGE BODY pkg_categoria AS

  PROCEDURE sp_categoria_create (
    p_nombre       IN  VARCHAR2,
    o_categoria_id OUT NUMBER
  ) AS
  BEGIN
    INSERT INTO Categoria (nombre)
    VALUES (p_nombre)
    RETURNING categoria_id INTO o_categoria_id;
  END;

  PROCEDURE sp_categoria_get_by_id (
    p_categoria_id IN NUMBER,
    o_cursor       OUT SYS_REFCURSOR
  ) AS
  BEGIN
    OPEN o_cursor FOR
      SELECT categoria_id, nombre
        FROM Categoria
       WHERE categoria_id = p_categoria_id;
  END;

  PROCEDURE sp_categoria_list (
    o_cursor OUT SYS_REFCURSOR
  ) AS
  BEGIN
    OPEN o_cursor FOR
      SELECT categoria_id, nombre
        FROM Categoria
       ORDER BY nombre;
  END;

  PROCEDURE sp_categoria_update (
    p_categoria_id IN NUMBER,
    p_nombre       IN VARCHAR2
  ) AS
  BEGIN
    UPDATE Categoria
       SET nombre = NVL(p_nombre, nombre)
     WHERE categoria_id = p_categoria_id;
  END;

  PROCEDURE sp_categoria_delete (
    p_categoria_id IN NUMBER
  ) AS
    v_count NUMBER;
  BEGIN
    -- opcional: validar si hay productos en esa categoría
    SELECT COUNT(*)
      INTO v_count
      FROM Producto
     WHERE categoria_id = p_categoria_id;

    IF v_count > 0 THEN
      RAISE_APPLICATION_ERROR(-20050, 'La categoría tiene productos asociados.');
    END IF;

    DELETE FROM Categoria
     WHERE categoria_id = p_categoria_id;
  END;

END pkg_categoria;
/
SHOW ERRORS


/* =========================================================
   PAQUETE: pkg_cliente
   Gestiona los clientes del sistema
   ========================================================= */
CREATE OR REPLACE PACKAGE pkg_cliente AS
  PROCEDURE sp_cliente_create (
    p_nombre    IN VARCHAR2,
    p_email     IN VARCHAR2,
    p_telefono  IN VARCHAR2,
    p_direccion IN VARCHAR2,
    p_estado    IN VARCHAR2 DEFAULT 'ACTIVO',
    o_cliente_id OUT NUMBER
  );

  PROCEDURE sp_cliente_get_by_id (
    p_cliente_id IN NUMBER,
    o_cursor     OUT SYS_REFCURSOR
  );

  PROCEDURE sp_cliente_list (
    o_cursor OUT SYS_REFCURSOR
  );

  PROCEDURE sp_cliente_update (
    p_cliente_id IN NUMBER,
    p_nombre     IN VARCHAR2,
    p_email      IN VARCHAR2,
    p_telefono   IN VARCHAR2,
    p_direccion  IN VARCHAR2,
    p_estado     IN VARCHAR2
  );

  PROCEDURE sp_cliente_delete (
    p_cliente_id IN NUMBER
  );
END pkg_cliente;
/
SHOW ERRORS


CREATE OR REPLACE PACKAGE BODY pkg_cliente AS

  PROCEDURE sp_cliente_create (
    p_nombre     IN VARCHAR2,
    p_email      IN VARCHAR2,
    p_telefono   IN VARCHAR2,
    p_direccion  IN VARCHAR2,
    p_estado     IN VARCHAR2,
    o_cliente_id OUT NUMBER
  ) AS
  BEGIN
    INSERT INTO Cliente (nombre, email, telefono, direccion, creado_en, estado)
    VALUES (p_nombre, p_email, p_telefono, p_direccion, SYSDATE, NVL(p_estado,'ACTIVO'))
    RETURNING cliente_id INTO o_cliente_id;
  END;

  PROCEDURE sp_cliente_get_by_id (
    p_cliente_id IN NUMBER,
    o_cursor     OUT SYS_REFCURSOR
  ) AS
  BEGIN
    OPEN o_cursor FOR
      SELECT *
        FROM Cliente
       WHERE cliente_id = p_cliente_id;
  END;

  PROCEDURE sp_cliente_list (
    o_cursor OUT SYS_REFCURSOR
  ) AS
  BEGIN
    OPEN o_cursor FOR
      SELECT *
        FROM Cliente
       ORDER BY creado_en DESC;
  END;

  PROCEDURE sp_cliente_update (
    p_cliente_id IN NUMBER,
    p_nombre     IN VARCHAR2,
    p_email      IN VARCHAR2,
    p_telefono   IN VARCHAR2,
    p_direccion  IN VARCHAR2,
    p_estado     IN VARCHAR2
  ) AS
  BEGIN
    UPDATE Cliente
       SET nombre    = NVL(p_nombre, nombre),
           email     = NVL(p_email, email),
           telefono  = NVL(p_telefono, telefono),
           direccion = NVL(p_direccion, direccion),
           estado    = NVL(p_estado, estado)
     WHERE cliente_id = p_cliente_id;
  END;

  PROCEDURE sp_cliente_delete (
    p_cliente_id IN NUMBER
  ) AS
    v_pedidos NUMBER;
  BEGIN
    -- opcional: validar que no tenga pedidos
    SELECT COUNT(*)
      INTO v_pedidos
      FROM Pedido
     WHERE cliente_id = p_cliente_id;

    IF v_pedidos > 0 THEN
      RAISE_APPLICATION_ERROR(-20051, 'El cliente tiene pedidos registrados.');
    END IF;

    DELETE FROM Cliente
     WHERE cliente_id = p_cliente_id;
  END;

END pkg_cliente;
/
SHOW ERRORS

/* =========================================================
   PAQUETE: pkg_producto
   Gestiona los productos y su información básica
   ========================================================= */
CREATE OR REPLACE PACKAGE pkg_producto AS
  PROCEDURE sp_producto_create (
    p_sku          IN VARCHAR2,
    p_nombre       IN VARCHAR2,
    p_descripcion  IN VARCHAR2,
    p_precio_unit  IN NUMBER,
    p_stock_actual IN NUMBER,
    p_categoria_id IN NUMBER,
    p_activo       IN NUMBER DEFAULT 1,
    o_producto_id  OUT NUMBER
  );

  PROCEDURE sp_producto_get_by_id (
    p_producto_id IN NUMBER,
    o_cursor      OUT SYS_REFCURSOR
  );

  PROCEDURE sp_producto_list (
    o_cursor OUT SYS_REFCURSOR
  );

  PROCEDURE sp_producto_update (
    p_producto_id IN NUMBER,
    p_sku         IN VARCHAR2,
    p_nombre      IN VARCHAR2,
    p_descripcion IN VARCHAR2,
    p_precio_unit IN NUMBER,
    p_stock_actual IN NUMBER,
    p_categoria_id IN NUMBER,
    p_activo      IN NUMBER
  );

  PROCEDURE sp_producto_delete (
    p_producto_id IN NUMBER
  );

  -- función de apoyo
  FUNCTION fn_producto_stock (p_producto_id IN NUMBER) RETURN NUMBER;
END pkg_producto;
/
SHOW ERRORS


CREATE OR REPLACE PACKAGE BODY pkg_producto AS

  PROCEDURE sp_producto_create (
    p_sku          IN VARCHAR2,
    p_nombre       IN VARCHAR2,
    p_descripcion  IN VARCHAR2,
    p_precio_unit  IN NUMBER,
    p_stock_actual IN NUMBER,
    p_categoria_id IN NUMBER,
    p_activo       IN NUMBER,
    o_producto_id  OUT NUMBER
  ) AS
  BEGIN
    INSERT INTO Producto (
      sku, nombre, descripcion, precio_unit, stock_actual, categoria_id, activo
    ) VALUES (
      p_sku, p_nombre, p_descripcion, p_precio_unit,
      NVL(p_stock_actual,0), p_categoria_id, NVL(p_activo,1)
    )
    RETURNING producto_id INTO o_producto_id;
  END;

  PROCEDURE sp_producto_get_by_id (
    p_producto_id IN NUMBER,
    o_cursor      OUT SYS_REFCURSOR
  ) AS
  BEGIN
    OPEN o_cursor FOR
      SELECT p.producto_id,
             p.sku,
             p.nombre,
             p.descripcion,
             p.precio_unit,
             p.stock_actual,
             c.nombre AS categoria_nombre,
             p.activo
        FROM Producto p
        LEFT JOIN Categoria c ON c.categoria_id = p.categoria_id
       WHERE p.producto_id = p_producto_id;
  END;

  PROCEDURE sp_producto_list (
    o_cursor OUT SYS_REFCURSOR
  ) AS
  BEGIN
    OPEN o_cursor FOR
      SELECT p.producto_id,
             p.sku,
             p.nombre,
             p.precio_unit,
             p.stock_actual,
             p.activo,
             c.nombre AS categoria_nombre
        FROM Producto p
        LEFT JOIN Categoria c ON c.categoria_id = p.categoria_id
       ORDER BY p.nombre;
  END;

  PROCEDURE sp_producto_update (
    p_producto_id IN NUMBER,
    p_sku         IN VARCHAR2,
    p_nombre      IN VARCHAR2,
    p_descripcion IN VARCHAR2,
    p_precio_unit IN NUMBER,
    p_stock_actual IN NUMBER,
    p_categoria_id IN NUMBER,
    p_activo      IN NUMBER
  ) AS
  BEGIN
    UPDATE Producto
       SET sku          = NVL(p_sku, sku),
           nombre       = NVL(p_nombre, nombre),
           descripcion  = NVL(p_descripcion, descripcion),
           precio_unit  = NVL(p_precio_unit, precio_unit),
           stock_actual = NVL(p_stock_actual, stock_actual),
           categoria_id = NVL(p_categoria_id, categoria_id),
           activo       = NVL(p_activo, activo)
     WHERE producto_id  = p_producto_id;
  END;

  PROCEDURE sp_producto_delete (
    p_producto_id IN NUMBER
  ) AS
    v_det NUMBER;
  BEGIN
    -- validar que no esté en detalle de pedido
    SELECT COUNT(*) INTO v_det
      FROM Pedido_Det
     WHERE producto_id = p_producto_id;

    IF v_det > 0 THEN
      RAISE_APPLICATION_ERROR(-20052, 'El producto tiene movimientos de venta.');
    END IF;

    DELETE FROM Producto
     WHERE producto_id = p_producto_id;
  END;

  FUNCTION fn_producto_stock (p_producto_id IN NUMBER)
  RETURN NUMBER
  IS
    v_stock NUMBER;
  BEGIN
    SELECT stock_actual
      INTO v_stock
      FROM Producto
     WHERE producto_id = p_producto_id;
    RETURN v_stock;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 0;
  END;

END pkg_producto;
/
SHOW ERRORS

/* =========================================================
   PAQUETE: pkg_envio
   Gestiona los registros de envío asociados a un pedido
   ========================================================= */
CREATE OR REPLACE PACKAGE pkg_envio AS
  PROCEDURE sp_envio_create (
    p_pedido_id      IN NUMBER,
    p_direccion_envio IN VARCHAR2,
    p_empresa        IN VARCHAR2,
    p_guia           IN VARCHAR2,
    p_fecha_envio    IN DATE,
    p_fecha_entrega  IN DATE,
    p_estado         IN VARCHAR2,
    o_envio_id       OUT NUMBER
  );

  PROCEDURE sp_envio_get_by_id (
    p_envio_id IN NUMBER,
    o_cursor   OUT SYS_REFCURSOR
  );

  PROCEDURE sp_envio_by_pedido (
    p_pedido_id IN NUMBER,
    o_cursor    OUT SYS_REFCURSOR
  );

  PROCEDURE sp_envio_update (
    p_envio_id       IN NUMBER,
    p_direccion_envio IN VARCHAR2,
    p_empresa        IN VARCHAR2,
    p_guia           IN VARCHAR2,
    p_fecha_envio    IN DATE,
    p_fecha_entrega  IN DATE,
    p_estado         IN VARCHAR2
  );

  PROCEDURE sp_envio_delete (
    p_envio_id IN NUMBER
  );
END pkg_envio;
/
SHOW ERRORS


CREATE OR REPLACE PACKAGE BODY pkg_envio AS

  PROCEDURE sp_envio_create (
    p_pedido_id       IN NUMBER,
    p_direccion_envio IN VARCHAR2,
    p_empresa         IN VARCHAR2,
    p_guia            IN VARCHAR2,
    p_fecha_envio     IN DATE,
    p_fecha_entrega   IN DATE,
    p_estado          IN VARCHAR2,
    o_envio_id        OUT NUMBER
  ) AS
  BEGIN
    INSERT INTO Envio (
      pedido_id, direccion_envio, empresa, guia,
      fecha_envio, fecha_entrega, estado
    ) VALUES (
      p_pedido_id, p_direccion_envio, p_empresa, p_guia,
      p_fecha_envio, p_fecha_entrega, NVL(p_estado,'PENDIENTE')
    )
    RETURNING envio_id INTO o_envio_id;
  END;

  PROCEDURE sp_envio_get_by_id (
    p_envio_id IN NUMBER,
    o_cursor   OUT SYS_REFCURSOR
  ) AS
  BEGIN
    OPEN o_cursor FOR
      SELECT *
        FROM Envio
       WHERE envio_id = p_envio_id;
  END;

  PROCEDURE sp_envio_by_pedido (
    p_pedido_id IN NUMBER,
    o_cursor    OUT SYS_REFCURSOR
  ) AS
  BEGIN
    OPEN o_cursor FOR
      SELECT *
        FROM Envio
       WHERE pedido_id = p_pedido_id
       ORDER BY envio_id;
  END;

  PROCEDURE sp_envio_update (
    p_envio_id        IN NUMBER,
    p_direccion_envio IN VARCHAR2,
    p_empresa         IN VARCHAR2,
    p_guia            IN VARCHAR2,
    p_fecha_envio     IN DATE,
    p_fecha_entrega   IN DATE,
    p_estado          IN VARCHAR2
  ) AS
  BEGIN
    UPDATE Envio
       SET direccion_envio = NVL(p_direccion_envio, direccion_envio),
           empresa         = NVL(p_empresa, empresa),
           guia            = NVL(p_guia, guia),
           fecha_envio     = NVL(p_fecha_envio, fecha_envio),
           fecha_entrega   = NVL(p_fecha_entrega, fecha_entrega),
           estado          = NVL(p_estado, estado)
     WHERE envio_id = p_envio_id;
  END;

  PROCEDURE sp_envio_delete (
    p_envio_id IN NUMBER
  ) AS
  BEGIN
    DELETE FROM Envio
     WHERE envio_id = p_envio_id;
  END;

END pkg_envio;
/
SHOW ERRORS


/* =========================================================
   PAQUETE: pkg_inventario
   Registra movimientos de inventario y consulta histórico
   ========================================================= */
CREATE OR REPLACE PACKAGE pkg_inventario AS
  PROCEDURE sp_inv_registrar_mov (
    p_producto_id IN NUMBER,
    p_tipo        IN VARCHAR2, -- 'ENTRADA' / 'SALIDA' / 'AJUSTE'
    p_cantidad    IN NUMBER,
    p_motivo      IN VARCHAR2
  );

  PROCEDURE sp_inv_list_by_producto (
    p_producto_id IN NUMBER,
    o_cursor      OUT SYS_REFCURSOR
  );
END pkg_inventario;
/
SHOW ERRORS


CREATE OR REPLACE PACKAGE BODY pkg_inventario AS

  PROCEDURE sp_inv_registrar_mov (
    p_producto_id IN NUMBER,
    p_tipo        IN VARCHAR2,
    p_cantidad    IN NUMBER,
    p_motivo      IN VARCHAR2
  ) AS
  BEGIN
    INSERT INTO Inventario_Mov (producto_id, tipo, cantidad, motivo, creado_en)
    VALUES (p_producto_id, p_tipo, p_cantidad, p_motivo, SYSDATE);

    -- actualiza stock del producto
    IF p_tipo = 'ENTRADA' THEN
      UPDATE Producto
         SET stock_actual = stock_actual + p_cantidad
       WHERE producto_id  = p_producto_id;
    ELSIF p_tipo = 'SALIDA' THEN
      UPDATE Producto
         SET stock_actual = stock_actual - p_cantidad
       WHERE producto_id  = p_producto_id;
    END IF;
  END;

  PROCEDURE sp_inv_list_by_producto (
    p_producto_id IN NUMBER,
    o_cursor      OUT SYS_REFCURSOR
  ) AS
  BEGIN
    OPEN o_cursor FOR
      SELECT mov_id,
             producto_id,
             tipo,
             cantidad,
             motivo,
             creado_en
        FROM Inventario_Mov
       WHERE producto_id = p_producto_id
       ORDER BY creado_en DESC, mov_id DESC;
  END;

END pkg_inventario;
/
SHOW ERRORS



/* =========================================================
   (FUNCION + CRUD + TRIGGERS)
   Tablas objetivo: Pedido, Pedido_Det, Pago
   ========================================================= */

/* =========================================================
   [FUNCIÓN] fn_total_pedido
   - Calcula la suma de "total" en Pedido_Det para un pedido
   - Uso: soporte de recálculo de totales
   ========================================================= */
CREATE OR REPLACE FUNCTION fn_total_pedido (p_pedido_id IN NUMBER)
RETURN NUMBER
IS
  v_total NUMBER := 0;
BEGIN
  SELECT NVL(SUM(total), 0)
    INTO v_total
    FROM Pedido_Det
   WHERE pedido_id = p_pedido_id;

  RETURN v_total;
END;
/
SHOW ERRORS



/* =========================================================
   [CRUD PEDIDO] sp_pedido_create
   - Crea cabecera de pedido con totales en 0
   - OUT: o_pedido_id
   ========================================================= */
CREATE OR REPLACE PROCEDURE sp_pedido_create (
  p_cliente_id   IN  NUMBER,
  p_fecha_pedido IN  DATE     DEFAULT SYSDATE,
  p_estado       IN  VARCHAR2 DEFAULT 'CREADO',
  o_pedido_id    OUT NUMBER
) AS
BEGIN
  INSERT INTO Pedido (cliente_id, fecha_pedido, estado, total_bruto, total_desc, total_neto)
  VALUES (p_cliente_id, NVL(p_fecha_pedido, SYSDATE), p_estado, 0, 0, 0)
  RETURNING pedido_id INTO o_pedido_id;
END;
/
SHOW ERRORS


/* =========================================================
   [CRUD PEDIDO - CURSOR] sp_pedido_read_by_id
   - Devuelve 1 registro de Pedido por ID
   - CURSOR OUT: o_cursor (SYS_REFCURSOR)
   ========================================================= */
CREATE OR REPLACE PROCEDURE sp_pedido_read_by_id (
  p_pedido_id IN  NUMBER,
  o_cursor    OUT SYS_REFCURSOR
) AS
BEGIN
  OPEN o_cursor FOR
    SELECT p.*
      FROM Pedido p
     WHERE p.pedido_id = p_pedido_id;
END;
/
SHOW ERRORS;


/* =========================================================
   [CRUD PEDIDO] sp_pedido_update
   - Actualiza estado y/o total_desc; recalcula total_neto
   - Bloquea cambios si estado es PAGADO o CANCELADO
   ========================================================= */
CREATE OR REPLACE PROCEDURE sp_pedido_update (
  p_pedido_id    IN NUMBER,
  p_estado       IN VARCHAR2,
  p_total_desc   IN NUMBER DEFAULT NULL
) AS
  v_estado VARCHAR2(20);
BEGIN
  SELECT estado INTO v_estado FROM Pedido WHERE pedido_id = p_pedido_id FOR UPDATE;

  IF v_estado IN ('PAGADO','CANCELADO') THEN
    RAISE_APPLICATION_ERROR(-20010, 'No se puede modificar un pedido PAGADO o CANCELADO.');
  END IF;

  UPDATE Pedido
     SET estado     = NVL(p_estado, estado),
         total_desc = COALESCE(p_total_desc, total_desc),
         total_neto = (total_bruto - COALESCE(p_total_desc, total_desc))
   WHERE pedido_id  = p_pedido_id;
END;
/
SHOW ERRORS


/* =========================================================
   [CRUD PEDIDO] sp_pedido_delete
   - Elimina pedido y sus detalles
   - Impide borrar si el pedido ya tiene pagos o está PAGADO
   ========================================================= */
CREATE OR REPLACE PROCEDURE sp_pedido_delete (
  p_pedido_id IN NUMBER
) AS
  v_pagos  NUMBER;
  v_estado VARCHAR2(20);
BEGIN
  SELECT estado INTO v_estado FROM Pedido WHERE pedido_id = p_pedido_id;

  IF v_estado = 'PAGADO' THEN
    RAISE_APPLICATION_ERROR(-20011, 'No se puede borrar un pedido PAGADO.');
  END IF;

  SELECT COUNT(*) INTO v_pagos FROM Pago WHERE pedido_id = p_pedido_id;
  IF v_pagos > 0 THEN
    RAISE_APPLICATION_ERROR(-20012, 'No se puede borrar: el pedido tiene pagos.');
  END IF;

  DELETE FROM Pedido_Det WHERE pedido_id = p_pedido_id;
  DELETE FROM Pedido     WHERE pedido_id = p_pedido_id;
END;
/
SHOW ERRORS



/* =========================================================
   [CRUD PEDIDO_DET] sp_pedido_det_create
   - Inserta línea de detalle; calcula total de línea
   - Bloquea si pedido está PAGADO o CANCELADO
   ========================================================= */
CREATE OR REPLACE PROCEDURE sp_pedido_det_create (
  p_pedido_id     IN  NUMBER,
  p_producto_id   IN  NUMBER,
  p_cantidad      IN  NUMBER,
  p_precio_unit   IN  NUMBER,
  o_pedido_det_id OUT NUMBER
) AS
  v_estado VARCHAR2(20);
BEGIN
  SELECT estado INTO v_estado FROM Pedido WHERE pedido_id = p_pedido_id FOR UPDATE;
  IF v_estado IN ('PAGADO','CANCELADO') THEN
    RAISE_APPLICATION_ERROR(-20020, 'No se puede agregar detalle a un pedido PAGADO o CANCELADO.');
  END IF;

  INSERT INTO Pedido_Det (pedido_id, producto_id, cantidad, precio_unit, total)
  VALUES (p_pedido_id, p_producto_id, p_cantidad, p_precio_unit, p_cantidad * p_precio_unit)
  RETURNING pedido_det_id INTO o_pedido_det_id;
END;
/
SHOW ERRORS


/* =========================================================
   [CRUD PEDIDO_DET - CURSOR] sp_pedido_det_read_by_pedido
   - Lista detalles (líneas) de un pedido por su ID
   - CURSOR OUT: o_cursor (SYS_REFCURSOR)
   ========================================================= */

CREATE OR REPLACE PROCEDURE sp_pedido_det_read_by_pedido (
  p_pedido_id IN  NUMBER,
  o_cursor    OUT SYS_REFCURSOR
) AS
BEGIN
  OPEN o_cursor FOR
    SELECT d.pedido_det_id,
           d.pedido_id,
           d.producto_id,
           pr.nombre AS producto_nombre,
           d.cantidad,
           d.precio_unit,
           d.total
      FROM Pedido_Det d
      JOIN Producto pr ON pr.producto_id = d.producto_id
     WHERE d.pedido_id = p_pedido_id
     ORDER BY d.pedido_det_id;
END;
/
SHOW ERRORS;


/* =========================================================
   [CRUD PEDIDO_DET] sp_pedido_det_update
   - Actualiza cantidad/precio_unit; recalcula total de línea
   - Bloquea si pedido está PAGADO o CANCELADO
   ========================================================= */
CREATE OR REPLACE PROCEDURE sp_pedido_det_update (
  p_pedido_det_id IN NUMBER,
  p_cantidad      IN NUMBER,
  p_precio_unit   IN NUMBER
) AS
  v_pedido_id NUMBER;
  v_estado    VARCHAR2(20);
  v_cant      NUMBER;
  v_prec      NUMBER;
BEGIN
  SELECT pedido_id     INTO v_pedido_id FROM Pedido_Det WHERE pedido_det_id = p_pedido_det_id;
  SELECT estado        INTO v_estado    FROM Pedido     WHERE pedido_id = v_pedido_id FOR UPDATE;

  IF v_estado IN ('PAGADO','CANCELADO') THEN
    RAISE_APPLICATION_ERROR(-20021, 'No se puede actualizar un detalle de pedido PAGADO o CANCELADO.');
  END IF;

  SELECT NVL(p_cantidad, cantidad),
         NVL(p_precio_unit, precio_unit)
    INTO v_cant, v_prec
    FROM Pedido_Det
   WHERE pedido_det_id = p_pedido_det_id
   FOR UPDATE;

  UPDATE Pedido_Det
     SET cantidad    = v_cant,
         precio_unit = v_prec,
         total       = v_cant * v_prec
   WHERE pedido_det_id = p_pedido_det_id;
END;
/
SHOW ERRORS


/* =========================================================
   [CRUD PEDIDO_DET] sp_pedido_det_delete
   - Elimina una línea de detalle
   - Bloquea si pedido está PAGADO o CANCELADO
   ========================================================= */
CREATE OR REPLACE PROCEDURE sp_pedido_det_delete (
  p_pedido_det_id IN NUMBER
) AS
  v_pedido_id NUMBER;
  v_estado    VARCHAR2(20);
BEGIN
  SELECT pedido_id INTO v_pedido_id FROM Pedido_Det WHERE pedido_det_id = p_pedido_det_id;
  SELECT estado    INTO v_estado    FROM Pedido     WHERE pedido_id = v_pedido_id FOR UPDATE;

  IF v_estado IN ('PAGADO','CANCELADO') THEN
    RAISE_APPLICATION_ERROR(-20022, 'No se puede eliminar detalle de un pedido PAGADO o CANCELADO.');
  END IF;

  DELETE FROM Pedido_Det WHERE pedido_det_id = p_pedido_det_id;
END;
/
SHOW ERRORS



/* =========================================================
   [CRUD PAGO] sp_pago_create
   - Inserta pago; no permite en pedidos CANCELADO
   ========================================================= */
CREATE OR REPLACE PROCEDURE sp_pago_create (
  p_pedido_id  IN  NUMBER,
  p_metodo     IN  VARCHAR2,
  p_monto      IN  NUMBER,
  p_fecha_pago IN  DATE,
  p_estado     IN  VARCHAR2 DEFAULT NULL,
  o_pago_id    OUT NUMBER
) AS
  v_estado VARCHAR2(20);
BEGIN
  SELECT estado INTO v_estado FROM Pedido WHERE pedido_id = p_pedido_id FOR UPDATE;
  IF v_estado = 'CANCELADO' THEN
    RAISE_APPLICATION_ERROR(-20030, 'No se pueden registrar pagos sobre un pedido CANCELADO.');
  END IF;

  INSERT INTO Pago (pedido_id, metodo, monto, fecha_pago, estado)
  VALUES (p_pedido_id, p_metodo, p_monto, p_fecha_pago, p_estado)
  RETURNING pago_id INTO o_pago_id;
END;
/
SHOW ERRORS


/* =========================================================
   [CRUD PAGO - CURSOR] sp_pago_read_by_pedido
   - Lista pagos asociados a un pedido por su ID
   - CURSOR OUT: o_cursor (SYS_REFCURSOR)
   ========================================================= */
CREATE OR REPLACE PROCEDURE sp_pago_read_by_pedido (
  p_pedido_id IN  NUMBER,
  o_cursor    OUT SYS_REFCURSOR
) AS
BEGIN
  OPEN o_cursor FOR
    SELECT pago_id, pedido_id, metodo, monto, fecha_pago, estado
      FROM Pago
     WHERE pedido_id = p_pedido_id
     ORDER BY fecha_pago, pago_id;
END;
/
SHOW ERRORS;


/* =========================================================
   [CRUD PAGO] sp_pago_update
   - Actualiza método/monto/fecha/estado
   - Impide cambios si el pedido está CANCELADO
   ========================================================= */
CREATE OR REPLACE PROCEDURE sp_pago_update (
  p_pago_id    IN NUMBER,
  p_metodo     IN VARCHAR2,
  p_monto      IN NUMBER,
  p_fecha_pago IN DATE,
  p_estado     IN VARCHAR2
) AS
  v_pedido_id NUMBER;
  v_estado    VARCHAR2(20);
BEGIN
  SELECT pedido_id INTO v_pedido_id FROM Pago   WHERE pago_id = p_pago_id;
  SELECT estado    INTO v_estado    FROM Pedido WHERE pedido_id = v_pedido_id FOR UPDATE;

  IF v_estado = 'CANCELADO' THEN
    RAISE_APPLICATION_ERROR(-20031, 'No se pueden modificar pagos de un pedido CANCELADO.');
  END IF;

  UPDATE Pago
     SET metodo     = NVL(p_metodo, metodo),
         monto      = NVL(p_monto, monto),
         fecha_pago = NVL(p_fecha_pago, fecha_pago),
         estado     = NVL(p_estado, estado)
   WHERE pago_id = p_pago_id;
END;
/
SHOW ERRORS


/* =========================================================
   [CRUD PAGO] sp_pago_delete
   - Elimina un pago
   - Impide eliminar si pedido está CANCELADO
   ========================================================= */
CREATE OR REPLACE PROCEDURE sp_pago_delete (
  p_pago_id IN NUMBER
) AS
  v_pedido_id NUMBER;
  v_estado    VARCHAR2(20);
BEGIN
  SELECT pedido_id INTO v_pedido_id FROM Pago WHERE pago_id = p_pago_id;
  SELECT estado    INTO v_estado    FROM Pedido WHERE pedido_id = v_pedido_id FOR UPDATE;

  IF v_estado = 'CANCELADO' THEN
    RAISE_APPLICATION_ERROR(-20032, 'No se pueden eliminar pagos de un pedido CANCELADO.');
  END IF;

  DELETE FROM Pago WHERE pago_id = p_pago_id;
END;
/
SHOW ERRORS



/* =========================================================
   [TRIGGER #1] trg_det_bi_set_total
   - BEFORE INSERT/UPDATE en Pedido_Det
   - Calcula el total de la línea = cantidad * precio_unit
   ========================================================= */
CREATE OR REPLACE TRIGGER trg_det_bi_set_total
BEFORE INSERT OR UPDATE OF cantidad, precio_unit ON Pedido_Det
FOR EACH ROW
BEGIN
  :NEW.total := :NEW.cantidad * :NEW.precio_unit;
END;
/
SHOW ERRORS


/* =========================================================
   [TRIGGER #2] trg_det_aud_recalc_pedido
   - AFTER INSERT/UPDATE/DELETE en Pedido_Det
   - Recalcula total_bruto y total_neto del Pedido afectado
   ========================================================= */
CREATE OR REPLACE TRIGGER trg_det_aud_recalc_pedido
AFTER INSERT OR UPDATE OR DELETE ON Pedido_Det
FOR EACH ROW
DECLARE
  v_pedido_id NUMBER;
  v_bruto     NUMBER;
  v_desc      NUMBER;
BEGIN
  IF INSERTING OR UPDATING THEN
    v_pedido_id := :NEW.pedido_id;
  ELSE
    v_pedido_id := :OLD.pedido_id;
  END IF;

  SELECT NVL(SUM(total),0)
    INTO v_bruto
    FROM Pedido_Det
   WHERE pedido_id = v_pedido_id;

  SELECT total_desc
    INTO v_desc
    FROM Pedido
   WHERE pedido_id = v_pedido_id;

  UPDATE Pedido
     SET total_bruto = v_bruto,
         total_neto  = v_bruto - NVL(v_desc,0)
   WHERE pedido_id   = v_pedido_id;
END;
/
SHOW ERRORS


/* =========================================================
   [TRIGGER #3] trg_det_ai_stock_out
   - AFTER INSERT en Pedido_Det
   - Disminuye stock y registra salida en Inventario_Mov
   ========================================================= */
CREATE OR REPLACE TRIGGER trg_det_ai_stock_out
AFTER INSERT ON Pedido_Det
FOR EACH ROW
BEGIN
  UPDATE Producto
     SET stock_actual = stock_actual - :NEW.cantidad
   WHERE producto_id  = :NEW.producto_id;

  INSERT INTO Inventario_Mov (producto_id, tipo, cantidad, motivo, creado_en)
  VALUES (:NEW.producto_id, 'SALIDA', :NEW.cantidad, 'Venta pedido ' || :NEW.pedido_id, SYSDATE);
END;
/
SHOW ERRORS


/* =========================================================
   [TRIGGER #4] trg_det_ad_stock_in
   - AFTER DELETE en Pedido_Det
   - Devuelve stock y registra entrada en Inventario_Mov
   ========================================================= */
CREATE OR REPLACE TRIGGER trg_det_ad_stock_in
AFTER DELETE ON Pedido_Det
FOR EACH ROW
BEGIN
  UPDATE Producto
     SET stock_actual = stock_actual + :OLD.cantidad
   WHERE producto_id  = :OLD.producto_id;

  INSERT INTO Inventario_Mov (producto_id, tipo, cantidad, motivo, creado_en)
  VALUES (:OLD.producto_id, 'ENTRADA', :OLD.cantidad, 'Reverso venta pedido ' || :OLD.pedido_id, SYSDATE);
END;
/
SHOW ERRORS


/* =========================================================
   [TRIGGER #5] trg_pago_ai_set_pagado
   - AFTER INSERT/UPDATE/DELETE en Pago
   - Marca Pedido como PAGADO cuando sum(monto) >= total_neto
   - Si baja de total_neto, revierte a CREADO (si estaba PAGADO)
   ========================================================= */
CREATE OR REPLACE TRIGGER trg_pago_ai_set_pagado
AFTER INSERT OR UPDATE OR DELETE ON Pago
FOR EACH ROW
DECLARE
  v_pedido_id NUMBER;
  v_pagado    NUMBER;
  v_total     NUMBER;
  v_estado    VARCHAR2(20);
BEGIN
  IF INSERTING OR UPDATING THEN
    v_pedido_id := :NEW.pedido_id;
  ELSE
    v_pedido_id := :OLD.pedido_id;
  END IF;

  SELECT NVL(SUM(monto),0)
    INTO v_pagado
    FROM Pago
   WHERE pedido_id = v_pedido_id;

  SELECT total_neto, estado
    INTO v_total, v_estado
    FROM Pedido
   WHERE pedido_id = v_pedido_id;

  UPDATE Pedido
     SET estado =
       CASE
         WHEN v_pagado >= v_total THEN 'PAGADO'
         ELSE CASE WHEN v_estado = 'PAGADO' THEN 'CREADO' ELSE v_estado END
       END
   WHERE pedido_id = v_pedido_id;
END;
/
SHOW ERRORS


/* =========================================================
   VISTAS DE CONSULTA Y REPORTES
   ========================================================= */

-- 1. Vista de resumen de pedidos con cliente
CREATE OR REPLACE VIEW vw_resumen_pedidos AS
SELECT p.pedido_id,
       c.nombre AS cliente,
       p.fecha_pedido,
       p.estado,
       p.total_bruto,
       p.total_desc,
       p.total_neto
  FROM Pedido p
  JOIN Cliente c ON c.cliente_id = p.cliente_id;

-- 2. Vista de productos con su categoría
CREATE OR REPLACE VIEW vw_productos_stock AS
SELECT pr.producto_id,
       pr.nombre AS producto,
       pr.precio_unit,
       pr.stock_actual,
       ca.nombre AS categoria,
       pr.activo
  FROM Producto pr
  JOIN Categoria ca ON ca.categoria_id = pr.categoria_id;

-- 3. Vista de pagos con datos del pedido
CREATE OR REPLACE VIEW vw_pagos_detalle AS
SELECT pa.pago_id,
       pa.pedido_id,
       pe.cliente_id,
       pa.metodo,
       pa.monto,
       pa.fecha_pago,
       pa.estado
  FROM Pago pa
  JOIN Pedido pe ON pe.pedido_id = pa.pedido_id;

-- 4. Vista de envíos pendientes o en tránsito
CREATE OR REPLACE VIEW vw_envios_activos AS
SELECT e.envio_id,
       e.pedido_id,
       e.empresa,
       e.guia,
       e.estado,
       e.fecha_envio,
       e.fecha_entrega
  FROM Envio e
 WHERE e.estado IN ('PENDIENTE', 'EN TRÁNSITO');

-- 5. Vista de movimientos de inventario
CREATE OR REPLACE VIEW vw_movimientos_inventario AS
SELECT m.mov_id,
       m.producto_id,
       p.nombre AS producto,
       m.tipo,
       m.cantidad,
       m.motivo,
       m.creado_en
  FROM Inventario_Mov m
  JOIN Producto p ON p.producto_id = m.producto_id;

-- 6. Vista de top clientes (más pedidos)
CREATE OR REPLACE VIEW vw_top_clientes AS
SELECT c.cliente_id,
       c.nombre,
       COUNT(p.pedido_id) AS total_pedidos
  FROM Cliente c
  LEFT JOIN Pedido p ON p.cliente_id = c.cliente_id
 GROUP BY c.cliente_id, c.nombre
 ORDER BY total_pedidos DESC;

-- 7. Vista de productos más vendidos
CREATE OR REPLACE VIEW vw_top_productos AS
SELECT pr.producto_id,
       pr.nombre,
       SUM(d.cantidad) AS total_vendido
  FROM Producto pr
  JOIN Pedido_Det d ON d.producto_id = pr.producto_id
 GROUP BY pr.producto_id, pr.nombre
 ORDER BY total_vendido DESC;

-- 8. Vista de pedidos pendientes de pago
CREATE OR REPLACE VIEW vw_pedidos_pendientes AS
SELECT p.pedido_id,
       c.nombre AS cliente,
       p.fecha_pedido,
       p.total_neto,
       NVL(SUM(pg.monto),0) AS monto_pagado,
       (p.total_neto - NVL(SUM(pg.monto),0)) AS saldo_pendiente
  FROM Pedido p
  JOIN Cliente c ON c.cliente_id = p.cliente_id
  LEFT JOIN Pago pg ON pg.pedido_id = p.pedido_id
 WHERE p.estado != 'PAGADO'
 GROUP BY p.pedido_id, c.nombre, p.fecha_pedido, p.total_neto;

-- 9. Vista de ventas mensuales
CREATE OR REPLACE VIEW vw_resumen_ventas_mes AS
SELECT TO_CHAR(p.fecha_pedido, 'YYYY-MM') AS mes,
       SUM(p.total_neto) AS total_ventas
  FROM Pedido p
 GROUP BY TO_CHAR(p.fecha_pedido, 'YYYY-MM')
 ORDER BY mes;

-- 10. Vista de inventario valorizado
CREATE OR REPLACE VIEW vw_inventario_valorizado AS
SELECT pr.producto_id,
       pr.nombre,
       pr.precio_unit,
       pr.stock_actual,
       (pr.precio_unit * pr.stock_actual) AS valor_inventario
  FROM Producto pr;

