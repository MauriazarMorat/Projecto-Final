import cv2
import os
import time
import threading
import json
from collections import deque
from datetime import datetime

class VideoCapture:
    def __init__(self, device_index=1, buffer_size=30):
        self.device_index = device_index
        self.buffer_size = buffer_size
        self.frame_buffer = deque(maxlen=buffer_size)
        self.latest_frame = None
        self.captured_frames = []
        self.is_running = False
        self.capture_thread = None
        self.fps = 30
        self.frame_delay = 1.0 / 30

        current_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(current_dir)
        self.save_dir = os.path.join(project_root, "carpeta_frames/before")
        os.makedirs(self.save_dir, exist_ok=True)

        self.json_file = os.path.join(project_root, "flight_captures.json")
        self.flight_captures = self.load_flight_captures()

    def load_flight_captures(self):
        try:
            if os.path.exists(self.json_file):
                with open(self.json_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            else:
                return {}
        except Exception as e:
            print(f"Error al cargar {self.json_file}: {e}")
            return {}

    def start_capture(self):
        """Inicia la captura, esperando a que la cámara esté lista"""
        print("🎥 Inicializando cámara...")
        cap = cv2.VideoCapture(self.device_index)

        # Esperar hasta que OpenCV abra la cámara realmente
        start_time = time.time()
        while not cap.isOpened():
            if time.time() - start_time > 240:
                print("❌ No se pudo abrir la cámara (timeout de 240 s).")
                return False
            time.sleep(0.5)
            cap.open(self.device_index)

        print("✅ Cámara detectada, esperando primer frame...")

        # Esperar hasta recibir el primer frame real
        for i in range(60):  # hasta 30 segundos
            ret, frame = cap.read()
            if ret:
                print(f"✅ Primer frame recibido (intento {i+1})")
                self.latest_frame = frame.copy()
                break
            time.sleep(0.5)
        else:
            print("❌ No se recibió ningún frame en 30 segundos.")
            cap.release()
            return False

        # Cámara lista → cerrar prueba y empezar el hilo
        cap.release()
        print("🚀 Cámara lista, iniciando captura en hilo separado...")
        self.is_running = True
        self.capture_thread = threading.Thread(target=self._capture_loop, daemon=True)
        self.capture_thread.start()
        return True
    
    def get_latest_frame(self):
        return self.latest_frame

    def _capture_loop(self):
        cap = cv2.VideoCapture(self.device_index)

        if not cap.isOpened():
            print(f"❌ Error: No se pudo abrir la cámara en el índice {self.device_index}")
            self.is_running = False
            return

        self.fps = cap.get(cv2.CAP_PROP_FPS) or 30
        self.frame_delay = 1.0 / self.fps

        print(f"✅ Cámara conectada - FPS: {self.fps}")

        while self.is_running:
            ret, frame = cap.read()
            if not ret:
                time.sleep(0.1)
                continue
            self.latest_frame = frame.copy()
            self.frame_buffer.append(frame)
            time.sleep(self.frame_delay)

        cap.release()
        print("📸 Cámara liberada")

    def stop_capture(self):
        self.is_running = False
        if self.capture_thread:
            self.capture_thread.join()
        print("🛑 Captura detenida")

    def get_status(self):
        return {
            "is_running": self.is_running,
            "has_frame": self.latest_frame is not None
        }

# --- EJECUCIÓN PRINCIPAL ---
if __name__ == "__main__":
    capturer = VideoCapture(device_index=1)

    if capturer.start_capture():  # Espera automáticamente a que la cámara esté lista
        try:
            while True:
                time.sleep(2)
                print(f"Estado: {capturer.get_status()}")
        except KeyboardInterrupt:
            print("\n🛑 Interrupción detectada, deteniendo cámara...")
            capturer.stop_capture()
            print("✅ Cámara detenida correctamente. Podés cerrar la terminal.")
    else:
        print("❌ No se pudo iniciar la captura (la cámara no respondió).")
