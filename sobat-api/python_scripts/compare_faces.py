import sys
import json

# Ensure user site-packages are visible (fix for PHP shell_exec environment)
sys.path.append('/Users/itsrtcorp/Library/Python/3.9/lib/python/site-packages')

try:
    import face_recognition
except ImportError:
    # Fallback: try adding common paths if the specific one above failed or wasn't enough
    sys.path.append('/Library/Frameworks/Python.framework/Versions/3.9/lib/python3.9/site-packages')
    try:
        import face_recognition
    except ImportError:
         print(json.dumps({"status": "error", "message": "Library 'face_recognition' (dlib) not installed on server."}))
         sys.exit(0)

def compare_faces(known_image_path, unknown_image_path):
    try:
        # Load the known image and encode it
        known_image = face_recognition.load_image_file(known_image_path)
        known_encodings = face_recognition.face_encodings(known_image)

        if not known_encodings:
            return {"status": "error", "message": "No face found in known image"}

        known_encoding = known_encodings[0]

        # Load the unknown image and encode it
        unknown_image = face_recognition.load_image_file(unknown_image_path)
        unknown_encodings = face_recognition.face_encodings(unknown_image)

        if not unknown_encodings:
            return {"status": "error", "message": "No face found in check-in image"}

        if len(unknown_encodings) > 1:
            return {"status": "error", "message": "Multiple faces detected in check-in image"}

        unknown_encoding = unknown_encodings[0]

        # Compare faces
        # tolerance=0.6 is default, lower is stricter
        results = face_recognition.compare_faces([known_encoding], unknown_encoding, tolerance=0.5)
        face_distance = face_recognition.face_distance([known_encoding], unknown_encoding)

        return {
            "status": "success",
            "match": bool(results[0]),
            "distance": float(face_distance[0])
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(json.dumps({"status": "error", "message": "Missing arguments"}))
        sys.exit(1)

    result = compare_faces(sys.argv[1], sys.argv[2])
    print(json.dumps(result))
