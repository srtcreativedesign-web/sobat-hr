import sys
import json
import os
import platform

# Add platform-specific site-packages paths
if platform.system() == 'Darwin':
    # macOS (development)
    user_site = os.path.expanduser('~/Library/Python/3.9/lib/python/site-packages')
    if user_site not in sys.path:
        sys.path.append(user_site)
# Linux (server) - standard paths are usually already in sys.path

try:
    import face_recognition
except ImportError as e:
    print(json.dumps({
        "status": "error", 
        "message": f"face_recognition not installed: {str(e)}", 
        "debug_sys_path": sys.path,
        "debug_executable": sys.executable,
        "debug_platform": platform.system()
    }))
    sys.exit(0)

def detect_face(image_path):
    try:
        # Debug: Check if file exists
        import os
        if not os.path.exists(image_path):
             return {"status": "error", "message": f"File not found at {image_path}"}
             
        # Robust loading: Exif fix, resize, and brute-force rotation
        from PIL import Image, ImageOps
        import numpy as np
        
        img = Image.open(image_path)
        img = ImageOps.exif_transpose(img)
        if img.mode != 'RGB':
            img = img.convert('RGB')
            
        img.thumbnail((1200, 1200))
        
        rotations = [img, img.rotate(90, expand=True), img.rotate(180, expand=True), img.rotate(270, expand=True)]
        face_locations = []
        for rot_img in rotations:
            arr = np.array(rot_img)
            locs = face_recognition.face_locations(arr)
            if locs:
                face_locations = locs
                break
        
        face_count = len(face_locations)

        return {
            "status": "success",
            "face_count": face_count,
            "message": f"Detected {face_count} face(s)."
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"status": "error", "message": "Missing arguments"}))
        sys.exit(1)

    result = detect_face(sys.argv[1])
    print(json.dumps(result))
