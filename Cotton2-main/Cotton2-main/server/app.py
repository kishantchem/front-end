import bcrypt
import cv2 as cv
import os
import pymongo

from datetime import datetime
import pytz
from flask import Flask, jsonify, make_response, request
from flask_jwt_extended import (
    JWTManager,
    get_jwt_identity,
    jwt_required,
    create_access_token,
)
from gridfs import GridFS
from pydantic import ValidationError
from pymongo import MongoClient
from werkzeug.utils import secure_filename

from clustering import main
from lines_1 import fiber_length_1
from lines_2 import fiber_length_2
from schemas import *
from segmentation import segment_threads

app = Flask(__name__)
app.config["UPLOAD_FOLDER"] = "uploads"
app.config["JWT_SECRET_KEY"] = "cotton123456"

jwt = JWTManager(app)

client = MongoClient("localhost", 27017)
db = client["cotton"]
users_collection = db["users"]
uploads_collection = db["uploads"]
grid_fs = GridFS(db, collection="files")

image_details_collection = db["image_details"]
image_details_collection.create_index([("user_id", pymongo.ASCENDING)])


def verify_password(plain_password, hashed_password):
    return bcrypt.checkpw(
        plain_password.encode("utf-8"), hashed_password.encode("utf-8")
    )


def generate_hashed_password(password):
    hashed_password = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())
    return hashed_password.decode("utf-8")


@app.route("/")
@jwt_required()
def test():
    return jsonify({"msg": "success"}), 200


@app.route("/register", methods=["POST"])
def register():
    try:
        username = request.json.get("username")
        password = request.json.get("password")
        if not username or not password:
            return (
                jsonify({"msg": "Missing username or password", "result": "failure"}),
                400,
            )

        existing_user = users_collection.find_one({"username": username})
        if existing_user:
            return jsonify({"msg": "Username already exists", "result": "failure"}), 400

        hashed_password = generate_hashed_password(password)

        new_user = {"username": username, "password": hashed_password}

        users_collection.insert_one(new_user)
        return (
            jsonify({"msg": "User registered successfully", "result": "success"}),
            201,
        )

    except Exception as e:
        return jsonify({"msg": str(e), "result": "failure"}), 500


@app.route("/login", methods=["POST"])
def login():
    username = request.json.get("username")
    password = request.json.get("password")

    if not username or not password:
        return (
            jsonify({"msg": "Missing username or password", "result": "failure"}),
            401,
        )

    user = users_collection.find_one({"username": username})

    if user and verify_password(password, user["password"]):
        access_token = create_access_token(identity=username)
        return jsonify({"access_token": access_token, "result": "success"}), 200

    else:
        return jsonify({"msg": "Invalid credentials", "result": "failure"}), 401


def processImage(filename, operation, scale, method):
    img = cv.imread(f"uploads/{filename}")
    if operation == "cgray":
        imgProcessed = cv.cvtColor(img, cv.COLOR_BGR2GRAY)
        newFilename = f"static/{filename}"
        cv.imwrite(newFilename, imgProcessed)
        return newFilename

    elif operation == "resize":
        scale_percent = 50
        width = int(img.shape[1] * scale_percent / 100)
        height = int(img.shape[0] * scale_percent / 100)
        dim = (width, height)
        imgProcessed = cv.resize(img, dim, interpolation=cv.INTER_AREA)
        newFilename = f"static/{filename}"
        cv.imwrite(newFilename, imgProcessed)
        return newFilename

    elif operation == "getD":
        return img.shape

    elif operation == "lines":
        if method == 1:
            result = fiber_length_1(f"uploads/{filename}", scale)
        if method == 2:
            result = fiber_length_2(f"uploads/{filename}")
        return result

    else:
        raise ValueError(f"Unknown operation: {operation}")


def store_image_details(current_user, image_details_data, results_data):
    try:
        # Validate image details data and results data
        image_details = ImageDetails(**image_details_data)
        results = Results(**results_data)

        # Generate Test Number (auto-increment)
        latest_test_number = image_details_collection.find_one(sort=[("test_number", -1)])
        test_number = latest_test_number["test_number"] + 1 if latest_test_number else 1

        # Get IST timezone
        ist = pytz.timezone("Asia/Kolkata")

        # Get current time in IST
        current_time = datetime.now(ist)

        new_image_details = {
            "cotton_type": image_details.cotton_type,
            "station": image_details.station,
            "lot_number": image_details.lot_number,
            "test_number": test_number,
            "date": str(current_time),
            "msfl": results.msfl,
            "ifl": results.ifl,
            "ml": results.ml,
            "user_id": current_user,
        }

        image_details_collection.insert_one(new_image_details)
        return (
            jsonify(
                {
                    "msg": "Image details stored successfully",
                    "result": "success",
                    "test_number": test_number,
                }
            ),
            201,
        )
    except ValidationError as e:
        return (
            jsonify({"msg": f"Validation error: {e}", "result": "failure"}),
            422,
        )
    except Exception as e:
        return (
            jsonify({"msg": f"Error storing image details: {e}", "result": "failure"}),
            500,
        )


@app.route("/api/<version>/upload", methods=["POST"])
@jwt_required()
def upload_file(version):
    """
    Handle file uploads for different API versions.
    """
    current_user = get_jwt_identity()

    # Validate file presence
    file = request.files.get("file")
    if not file or file.filename == "":
        return jsonify({"msg": "No file provided or no selected file"}), 400

    # Save file locally and to GridFS
    file_path = os.path.join(app.config["UPLOAD_FOLDER"], file.filename)
    file.save(file_path)
    file_id = grid_fs.put(
        file.stream, filename=file.filename, content_type=file.content_type
    )

    # Record upload in the database
    user = users_collection.find_one({"username": current_user})
    uploads_collection.insert_one({"filid": file_id, "uploaded_by": user["_id"]})

    # Handle different API versions
    try:
        if version == "v1":
            method = int(request.form.get("method", 1))  # Default to 1 if not provided
            result = processImage(file.filename, "lines", 1, method)
        elif version == "v2":
            result = segment_threads(file.filename)
        elif version == "v3":
            # Request parameters
            calibration_factor = float(request.form.get("calibration_factor", 1.0))
            cotton_type = request.form.get("cotton_type", "")
            lot_number = request.form.get("lot_number", "")
            station = request.form.get("station", "")
            
            # Generate visualization and return binary stream
            buf, msfl, ifl, ml = main(file.filename, calibration_factor)
            
            # Store the input parameters along with their results
            image_details_data = {
                "cotton_type": cotton_type,
                "lot_number": lot_number,
                "station": station
            }
            results_data = {
                "msfl": msfl,
                "ifl": ifl,
                "ml": ml
            }
            store_image_details(current_user, image_details_data, results_data)
            
            # Send the results to the client as an image
            response = make_response(buf.getvalue())
            response.headers.set("Content-Type", "image/png")
            response.headers.set("Content-Disposition", "inline; filename=result.png")
            return response
        else:
            return jsonify({"msg": "Invalid API version"}), 400
    except Exception as e:
        return jsonify({"msg": f"Processing error: {e}"}), 500

    return jsonify({"length": result}), 200


# API to retrieve image details for the current user
@app.route("/api/v1/image_details", methods=["GET"])
@jwt_required()
def get_image_details():
    try:
        current_user = get_jwt_identity()

        image_details = list(image_details_collection.find({"user_id": current_user}))

        for detail in image_details:
            detail["_id"] = str(detail["_id"])

        return (
            jsonify(
                {
                    "msg": "Image details fetched successfully",
                    "result": "success",
                    "data": image_details,
                }
            ),
            200,
        )

    except Exception as e:
        return (
            jsonify(
                {"msg": f"Error retrieving image details: {e}", "result": "failure"}
            ),
            500,
        )


if __name__ == "__main__":
    app.run(debug=True, port=5001, host="0.0.0.0")
