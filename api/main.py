from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import mysql.connector
import os

app = FastAPI()

DB_HOST = os.environ.get("DB_HOST", "db")
DB_USER = os.environ.get("DB_USER", "myuser")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "mypass")
DB_NAME = os.environ.get("DB_NAME", "task_db")


# Pydanticモデル（API入出力定義用）
class Task(BaseModel):
    id: int = None
    title: str
    description: str = None
    done: bool = False


def get_connection():
    return mysql.connector.connect(
        host=DB_HOST, user=DB_USER, password=DB_PASSWORD, database=DB_NAME
    )


@app.on_event("startup")
def startup():
    """
    コンテナ起動時にテーブルがなければ作成する
    """
    conn = get_connection()
    cursor = conn.cursor()
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


@app.get("/tasks")
def get_tasks():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM tasks")
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return rows


@app.get("/tasks/{task_id}")
def get_task(task_id: int):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM tasks WHERE id = %s", (task_id,))
    row = cursor.fetchone()
    cursor.close()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Task not found")
    return row


@app.post("/tasks")
def create_task(task: Task):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO tasks (title, description, done) VALUES (%s, %s, %s)",
        (task.title, task.description, task.done),
    )
    conn.commit()
    new_id = cursor.lastrowid
    cursor.close()
    conn.close()
    return {"id": new_id, "message": "Task created"}


@app.put("/tasks/{task_id}")
def update_task(task_id: int, task: Task):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE tasks SET title=%s, description=%s, done=%s WHERE id=%s",
        (task.title, task.description, task.done, task_id),
    )
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Task updated"}


@app.delete("/tasks/{task_id}")
def delete_task(task_id: int):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM tasks WHERE id=%s", (task_id,))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Task deleted"}
