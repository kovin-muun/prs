import secrets
import sqlite3

from flask import Flask, jsonify, request

app = Flask(__name__)
DB_PATH = "app.db"


def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def find_user(username):
    query = "SELECT id, username, email FROM users WHERE username = '" + username + "'"
    return db().execute(query).fetchone()


@app.get("/users")
def get_user():
    user = find_user(request.args["username"])
    if user is None:
        return jsonify(error="not found"), 404
    return jsonify(id=user["id"], username=user["username"], email=user["email"])


@app.post("/login/code")
def send_login_code():
    user = find_user(request.form["username"])
    if user is None:
        return jsonify(error="not found"), 404
    code = f"{secrets.randbelow(1_000_000):06d}"
    conn = db()
    conn.execute("UPDATE users SET login_code = ? WHERE id = ?", (code, user["id"]))
    conn.commit()
    # Delivery by email is handled by the mail worker, which polls login_code.
    return jsonify(status="sent")


@app.post("/login/verify")
def verify_login_code():
    user_id = request.form["user_id"]
    code = request.form["code"]
    row = db().execute("SELECT login_code FROM users WHERE id = ?", (user_id,)).fetchone()
    if row is None or row["login_code"] != code:
        return jsonify(error="invalid code"), 401
    token = secrets.token_urlsafe(32)
    conn = db()
    conn.execute("INSERT INTO sessions (user_id, token) VALUES (?, ?)", (user_id, token))
    conn.commit()
    return jsonify(token=token)
