import os
import sys
import time
import mysql.connector


def init_schema():
    host = os.environ.get('MYSQL_HOST')
    port = int(os.environ.get('MYSQL_PORT', 3306))
    user = os.environ.get('MYSQL_USER')
    password = os.environ.get('MYSQL_PASSWORD')
    database = os.environ.get('MYSQL_DB')

    if not host or not password:
        print("MYSQL_HOST or MYSQL_PASSWORD not set. Skipping schema initialization.")
        return

    print(f"Connecting to MySQL at {host}:{port} as user '{user}' (database: '{database}')...")
    for attempt in range(1, 13):
        try:
            conn = mysql.connector.connect(
                host=host,
                port=port,
                user=user,
                password=password,
                database=database
            )
            cursor = conn.cursor()
            schema_path = os.path.join(os.path.dirname(__file__), 'schema.sql')
            with open(schema_path, 'r') as f:
                for statement in cursor.execute(f.read(), multi=True):
                    pass
            conn.commit()
            cursor.close()
            conn.close()
            print("Database schema initialized successfully!")
            return
        except Exception as e:
            print(f"Attempt {attempt}/12 failed: {e}. Retrying in 5 seconds...")
            time.sleep(5)

    print("Failed to initialize database after 12 attempts.")
    sys.exit(1)


if __name__ == '__main__':
    init_schema()
