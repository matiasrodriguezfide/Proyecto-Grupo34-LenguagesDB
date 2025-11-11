import oracledb
import os

DB_USER = os.getenv("ORA_USER")
DB_PASS = os.getenv("ORA_PASS")
DB_DSN  = os.getenv("ORA_DSN")

try:
    conn = oracledb.connect(
        user=DB_USER,
        password=DB_PASS,
        dsn=DB_DSN
    )
    print("Conexión exitosa")
    conn.close()
except Exception as e:
    print("Error:", e)
