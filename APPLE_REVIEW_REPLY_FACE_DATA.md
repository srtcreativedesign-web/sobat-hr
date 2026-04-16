# Apple App Review Reply — Face Data (under 4000 chars)

Copy the text below (between the lines) to paste into App Store Connect:

---

1. What face data does the app collect?

SOBAT HR collects 2D JPEG facial photographs only, in two contexts: (a) Face Enrollment — one reference photo from the front camera when an employee registers, and (b) Attendance Selfie — one photo each time an employee checks in. Google ML Kit Face Detection runs entirely on-device to validate face presence before capture. The app does NOT collect or store face embeddings, biometric templates, 3D face maps, or any persistent biometric identifiers.

2. Planned uses of face data

Face data is used exclusively for: (a) Identity verification — the enrollment photo is compared server-side against the check-in selfie using the open-source face_recognition library (dlib, tolerance 0.5) to confirm the employee's identity; (b) Fraud prevention — preventing buddy punching (one employee checking in for another); (c) HR review — mismatched results are flagged for manual review. Face data is NOT used for advertising, profiling, marketing, tracking, or any other purpose.

3. Third-party sharing and storage

Face data is NOT shared with any third party. No third-party facial recognition services (AWS Rekognition, Google Cloud Vision, etc.) are used — all processing runs on our own server. Google ML Kit runs offline on-device and sends no data to Google. Photos are stored on our company-controlled server, transmitted via HTTPS, and only temporarily cached on the device during upload.

4. Retention

Enrollment photos are retained during active employment and deleted when the employee record is removed or upon employee request. Attendance selfies are subject to automated daily cleanup. Face encodings are never stored — they are computed in memory during each verification and immediately discarded. Employees can delete their face data anytime via the app or HR administrator.

5. Privacy policy sections covering face data

Our updated privacy policy is at: [YOUR_PRIVACY_POLICY_URL]

Relevant sections: Section 1 "Data Wajah (Face Data)" describes collection. Section 3 is dedicated entirely to face data with subsections: 3.1 (collection), 3.2 (use), 3.3 (third-party sharing), 3.4 (storage), 3.5 (retention/deletion), 3.6 (user rights). Section 6 covers user rights including face data deletion. Section 7 describes camera permission usage for face enrollment and attendance selfies.

6. Specific privacy policy text concerning face data

From Section 3.1: "SOBAT HR collects facial photographs in two processes: Face Enrollment — a single reference photo captured via front camera, validated by on-device Google ML Kit; and Attendance Selfie — a selfie captured at each check-in for identity verification. Only compressed 2D JPEG photos are collected. No face embeddings, biometric templates, 3D face maps, or face geometry data are stored permanently. On-device face detection runs entirely locally and transmits no data to any third party."

From Section 3.2: "Face data is used exclusively for attendance identity verification, fraud prevention (anti-buddy punching), and HR administrative review. Face data is not used for advertising, profiling, marketing, or tracking."

From Section 3.3: "Face data is not sold, shared, or disclosed to any third party. All face comparison processing is performed on our own server using open-source libraries."

From Section 3.5: "Enrollment photos are retained during active employment and deleted upon employee request or record removal. Attendance photos are cleaned automatically via daily scheduled cleanup. Face encodings are never stored permanently — computed per verification and immediately discarded."

From Section 3.6: "Employees may delete their enrolled face data at any time, request information about stored face data, or opt out of face recognition."
