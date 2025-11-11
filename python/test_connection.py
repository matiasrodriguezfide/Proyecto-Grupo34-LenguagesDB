import oracledb

try:
    conn = oracledb.connect(
        user="coffeewild",
        password="wellwellwell",
        dsn="localhost:1521/XEPDB1"
    )
    print("Connexion exitosa")
    conn.close()
except Exception as e:
    print("Error:", e)
