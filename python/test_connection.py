import oracledb
from datetime import datetime

# conexión a la base de datos
try:
    connection = oracledb.connect(
        user="COFFEEWILD",
        password="...",
        dsn="localhost/XEPDB1"
    )
    cursor = connection.cursor()
    print("Conexión exitosa a Oracle CoffeeWild")
except Exception as e:
    print(f"Error al conectar: {e}")
    exit()

# crear pedido
def crear_pedido():
    try:
        pedido_id = cursor.var(int)
        cursor.callproc("SP_PEDIDO_CREATE", [1, datetime.now(), "CREADO", pedido_id])
        connection.commit()
        new_id = int(pedido_id.getvalue())
        print(f"Pedido creado correctamente. Nuevo ID: {new_id}")
        return new_id
    except Exception as e:
        print(f"Error al crear pedido: {e}")
        return None

# actualizar pedido
def actualizar_pedido(pedido_id):
    try:
        cursor.callproc("SP_PEDIDO_UPDATE", [pedido_id, "ENTREGADO"])
        connection.commit()
        print("Pedido actualizado correctamente.")
    except Exception as e:
        print(f"Error al actualizar pedido: {e}")

# registrar pago
def registrar_pago(pedido_id):
    try:
        pago_id = cursor.var(int)
        cursor.callproc("SP_PAGO_CREATE", [pedido_id, "TARJETA", 2500.00, datetime.now(), "CONFIRMADO", pago_id])
        connection.commit()
        print(f"Pago registrado correctamente. Nuevo ID: {pago_id.getvalue()}")
    except Exception as e:
        print(f"Error al registrar pago: {e}")

# ver resumen de pedidos
def ver_resumen_pedidos():
    print("\nRESUMEN DE PEDIDOS")
    try:
        cursor.execute("SELECT * FROM VW_RESUMEN_PEDIDOS")
        for row in cursor.fetchall():
            print(row)
    except Exception as e:
        print(f"Error al leer pedidos: {e}")

# flujo principal
print("=== CoffeeWild Project - Test CRUD ===")

pedido_id = crear_pedido()
if pedido_id:
    actualizar_pedido(pedido_id)
    registrar_pago(pedido_id)

ver_resumen_pedidos()

# cerrar conexión
cursor.close()
connection.close()
print("\nConexión cerrada correctamente.")
