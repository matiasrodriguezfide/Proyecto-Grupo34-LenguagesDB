Saludos profe,

Este proyecto corresponde al segundo avance del trabajo final de la materia Lenguajes de Bases de Datos.
El sistema simula una tienda llamada CoffeeWild, donde se gestionan clientes, pedidos, productos, pagos, envíos e inventario.

La estructura del repositorio es la siguiente:

/sql/ → contiene el script principal con la creación de tablas, vistas, triggers, funciones, paquetes y procedimientos almacenados.

/python/ → incluye el script test_connection.py, el cual establece la conexión a la base de datos Oracle y ejecuta un flujo de prueba (crear, actualizar y leer pedidos usando procedimientos almacenados).

/docs/ → contiene el diccionario de datos generado automáticamente desde SQL Developer.

Todo el proyecto se conecta a Oracle XE usando el usuario COFFEEWILD, cumpliendo con los requerimientos de la consigna (vistas, funciones, procedimientos, cursores, triggers y conexión por lenguaje externo).
