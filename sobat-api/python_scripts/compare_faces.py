import sys
import json
import os
import platform

# Cross-platform face_recognition import
try:
    import face_recognition
except ImportError:
    print(json.dumps({"status": "error", "message": "Library 'face_recognition' (dlib) not installed on server."}))
    sys.exit(0)

def compare_faces(known_image_path, unknown_image_path):
    try:
        # Helper to load, scale down, and brute-force orientations
        from PIL import Image, ImageOps
        import numpy as np
        
        def find_face_encodings_robustly(path):
            img = Image.open(path)
            img = ImageOps.exif_transpose(img) # Try EXIF first
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
            # Compress image mildly to speed up and improve HOG detection
            img.thumbnail((1200, 1200))
            
            # If standard EXIF failed, brute-force rotations (Samsung issue)
            rotations = [img, img.rotate(90, expand=True), img.rotate(180, expand=True), img.rotate(270, expand=True)]
            for rot_img in rotations:
                arr = np.array(rot_img)
                encs = face_recognition.face_encodings(arr)
                if encs:
                    return encs
            return []

        # Load the known image and encode it
        known_encodings = find_face_encodings_robustly(known_image_path)

        if not known_encodings:
            return {"status": "error", "message": "No face found in known image"}

        known_encoding = known_encodings[0]

        # Load the unknown image and encode it
        unknown_encodings = find_face_encodings_robustly(unknown_image_path)

        if not unknown_encodings:
            return {"status": "error", "message": "No face found in check-in image"}

        if len(unknown_encodings) > 1:
            return {"status": "error", "message": "Multiple faces detected in check-in image"}

        unknown_encoding = unknown_encodings[0]

        # Compare faces
        # tolerance=0.6 is default, lower is stricter
        results = face_recognition.compare_faces([known_encoding], unknown_encoding, tolerance=0.7)
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
