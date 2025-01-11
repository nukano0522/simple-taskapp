from flask import Flask, render_template, request, redirect, url_for, flash
import requests
import os
import logging

logging.basicConfig(level=logging.INFO)

# 環境変数からベースパスを取得（デフォルトは空文字列）
BASE_PATH = os.environ.get("BASE_PATH", "")

app = Flask(__name__, static_folder="static", template_folder="templates")
app.secret_key = "pass"  # Flashメッセージ用


# テンプレートにグローバル変数として追加
@app.context_processor
def inject_base_path():
    return dict(base_path=BASE_PATH)


# 環境変数からプロキシホスト名を取得
PROXY_HOST = os.environ.get("PROXY_HOST", "proxy-service")
API_URL = f"http://{PROXY_HOST}/app2/api/tasks"
# API_HOST = os.environ.get("API_HOST", "api-service")
# API_URL = f"http://{API_HOST}:8000/tasks"


@app.route("/")
def index():
    try:
        # タスク一覧を取得して表示
        resp = requests.get(API_URL)
        resp.raise_for_status()  # HTTPエラー時に例外発生
        tasks = resp.json()
    except requests.exceptions.RequestException as e:
        flash(f"Error fetching tasks: {e}")
        tasks = []  # エラー時は空のリストを表示
    return render_template("index.html", tasks=tasks)


@app.route("/add", methods=["POST"])
def add_task():
    # ログ
    app.logger.info("Adding task")
    title = request.form.get("title")
    description = request.form.get("description")
    data = {"title": title, "description": description, "done": False}
    try:
        resp = requests.post(API_URL, json=data)
        resp.raise_for_status()  # HTTPエラー時に例外発生
    except requests.exceptions.RequestException as e:
        flash(f"Error adding task: {e}")
    return redirect(url_for("index"))


@app.route("/delete/<int:task_id>")
def delete_task(task_id):
    try:
        resp = requests.delete(f"{API_URL}/{task_id}")
        resp.raise_for_status()  # HTTPエラー時に例外発生
    except requests.exceptions.RequestException as e:
        flash(f"Error deleting task: {e}")
    return redirect(url_for("index"))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
