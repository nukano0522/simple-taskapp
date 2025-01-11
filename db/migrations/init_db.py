import mysql.connector
import os
import time

DB_HOST = os.environ.get("DB_HOST", "db-service")
DB_USER = os.environ.get("DB_USER", "myuser")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "mypass")
DB_NAME = os.environ.get("DB_NAME", "task_db")


def get_connection():
    return mysql.connector.connect(
        host=DB_HOST, user=DB_USER, password=DB_PASSWORD, database=DB_NAME
    )


def run_migration():
    retries = 5
    for attempt in range(retries):
        try:
            print(f"Migration attempt {attempt + 1}")
            conn = get_connection()
            cursor = conn.cursor()

            # テーブル作成
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS tasks (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    title VARCHAR(255) NOT NULL,
                    description TEXT,
                    done BOOLEAN NOT NULL DEFAULT 0
                )
            """
            )

            conn.commit()
            cursor.close()
            conn.close()
            print("Migration completed successfully")
            break

        except mysql.connector.Error as err:
            print(f"Database error: {err}")
            if attempt < retries - 1:
                print("Retrying in 5 seconds...")
                time.sleep(5)
            else:
                raise


if __name__ == "__main__":
    run_migration()
