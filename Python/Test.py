import cv2
import os

video_path = os.path.join(os.path.dirname(__file__), "VideoTest.mp4")
cap = cv2.VideoCapture(video_path)

if not cap.isOpened():
    print(f"No se pudo abrir el video: {video_path}")
else:
    print("Video abierto correctamente")
    cap.release()
