# app.py
from flask import Flask, request, jsonify
from pymongo import MongoClient
from datetime import datetime
import os

app = Flask(__name__)

# MONGODB_URI example:
# mongodb://<username>:<password>@mongo:27017/?authSource=admin
MONGODB_URI = os.environ.get("MONGODB_URI", "mongodb://localhost:27017/")

client = MongoClient(MONGODB_URI)
# Use a named DB for clarity
db = client.flask_db
collection = db.data


@app.route("/")
def index():
    return f"Welcome to the Flask app! The current time is: {datetime.now()}"


@app.route("/data", methods=["GET", "POST"])
def data_route():
    if request.method == "POST":
        payload = request.get_json()
        if not payload:
            return jsonify({"error": "no json provided"}), 400
        collection.insert_one(payload)
        return jsonify({"status": "Data inserted"}), 201

    # GET
    docs = list(collection.find({}, {"_id": 0}))
    return jsonify(docs), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
