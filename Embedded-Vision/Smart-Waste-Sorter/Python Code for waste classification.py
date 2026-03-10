import cv2
import serial
import time
import threading
from flask import Flask, render_template_string
from picamera2 import Picamera2
import numpy as np
import os
 
# ---------------- SERIAL TO ARDUINO ----------------
arduino = serial.Serial('/dev/ttyUSB0', 9600, timeout=1)
time.sleep(2)
 
# ---------------- DASHBOARD VARIABLES ----------------
recycled_count = 0
rec_bin = 100
non_bin = 100
 
# ---------------- DASHBOARD ----------------
app = Flask(__name__)
 
HTML = """
<h2>Smart Waste Sorting Dashboard</h2>
<p>Recycled Items: {{count}}</p>
<p>Recyclable Bin Distance: {{rec}} cm</p>
<p>Non-Recyclable Bin Distance: {{non}} cm</p>
{% if rec < 5 %}
<h3 style='color:red;'>Recyclable Bin FULL</h3>
{% endif %}
"""
 
@app.route("/")
def index():
    return render_template_string(
        HTML,
        count=recycled_count,
        rec=rec_bin,
        non=non_bin
    )
 
# ---------------- SENSOR READING THREAD ----------------
def read_sensors():
    global rec_bin, non_bin
    while True:
        if arduino.in_waiting:
            try:
                line = arduino.readline().decode().strip()
                if line.startswith("REC:"):
                    parts = line.split(',')
                    rec_bin = int(parts[0].split(':')[1])
                    non_bin = int(parts[1].split(':')[1])
            except Exception as e:
                print("Arduino read error:", e)
        time.sleep(1)
 
threading.Thread(target=read_sensors, daemon=True).start()
threading.Thread(
    target=lambda: app.run(host='0.0.0.0', port=5000, debug=False),
    daemon=True
).start()
 
# ---------------- CAMERA ----------------
cam = Picamera2()
cam.start()
time.sleep(1)
 
last_detect_time = 0
DEBOUNCE_SECONDS = 2
 
# ---------------- LOAD DATABASE ----------------
orb = cv2.ORB_create()
bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
 
def load_database(folder):
    descriptors = []
    for filename in os.listdir(folder):
        path = os.path.join(folder, filename)
        img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
        if img is not None:
            kp, des = orb.detectAndCompute(img, None)
            if des is not None:
                descriptors.append(des)
    return descriptors
 
rec_db = load_database("recyclable")
nonrec_db = load_database("non_recyclable")
 
print(f"Loaded {len(rec_db)} recyclable and {len(nonrec_db)} non-recyclable images.")
 
# ---------------- CLASSIFICATION FUNCTION ----------------
def classify_object(des_obj, rec_db, nonrec_db, threshold=15):
    best_rec = 0
    best_nonrec = 0
    if des_obj is None:
        return "Non-Recyclable"
 
    for des_ref in rec_db:
        matches = bf.match(des_ref, des_obj)
        good_matches = len([m for m in matches if m.distance < 50])
        best_rec = max(best_rec, good_matches)
 
    for des_ref in nonrec_db:
        matches = bf.match(des_ref, des_obj)
        good_matches = len([m for m in matches if m.distance < 50])
        best_nonrec = max(best_nonrec, good_matches)
 
    if best_rec > best_nonrec :
        return "Recyclable"
    else:
        return "Non-Recyclable"
 
# ---------------- MAIN LOOP ----------------
while True:
    frame = cam.capture_array()
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (5, 5), 0)
    thresh = cv2.adaptiveThreshold(
        blur,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY_INV,
        11,
        2
    )
 
    contours, _ = cv2.findContours(
        thresh,
        cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE
    )
 
    classification = "Idle"
    current_time = time.time()
 
    if contours:
        c = max(contours, key=cv2.contourArea)
        area = cv2.contourArea(c)
        if area > 500:
            x, y, w, h = cv2.boundingRect(c)
            object_roi = gray[y:y+h, x:x+w]
            object_roi = cv2.resize(object_roi, (100, 100))  # resize for faster matching
            kp_obj, des_obj = orb.detectAndCompute(object_roi, None)
 
            if current_time - last_detect_time > DEBOUNCE_SECONDS:
                classification = classify_object(des_obj, rec_db, nonrec_db)
                if classification == "Recyclable":
                    recycled_count += 1
                    arduino.write(b'R')
                else:
                    arduino.write(b'N')
                last_detect_time = current_time
 
            cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
 
    cv2.putText(frame,
                f"{classification}",
                (20, 40),
                cv2.FONT_HERSHEY_SIMPLEX,
                1,
                (255, 0, 0),
                2)
 
    cv2.imshow("Smart Waste Sorting", frame)
    cv2.imshow("Threshold", thresh)
 
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
 
cam.stop()
cv2.destroyAllWindows()
arduino.close()