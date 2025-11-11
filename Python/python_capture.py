import cv2
import os
import time
import threading
import json
from collections import deque
from datetime import datetime
import shutil
import uuid

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
        
        # Auto-initialize camera on startup
        print("🎥 Auto-inicializando cámara...")
        self._initialize_camera()

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

    def _initialize_camera(self):
        """Initialize camera and start the capture loop in a background thread"""
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

    def start_capture(self):
        """No-op: camera is already initialized and running. This is called by server for compatibility."""
        print("DEBUG: start_capture called (camera already running)")
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
        """No-op: camera keeps running. This is never called in normal operation."""
        print("DEBUG: stop_capture called (camera will continue running)")

    def get_status(self):
        return {
            "is_running": self.is_running,
            "has_frame": self.latest_frame is not None
        }

    def save_flight_captures(self):
        try:
            with open(self.json_file, 'w', encoding='utf-8') as f:
                json.dump(self.flight_captures, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"Error guardando {self.json_file}: {e}")

    def capture_current_frame(self, ndv, ndc):
        """Save the latest frame to disk with naming NDC_{ndc}_NDV_{ndv}_NC_{count}.jpg in carpeta_frames/before"""
        if self.latest_frame is None:
            print("DEBUG: No hay frame disponible para capturar")
            return (len(self.captured_frames), datetime.utcnow().strftime('%Y%m%d_%H%M%S'), "")

        flight_key = f"{ndc}_{ndv}"
        
        # Get the current capture count for this flight
        current_count = self.flight_captures.get(flight_key, 0) + 1
        
        # Build filename: NDC_{ndc}_NDV_{ndv}_NC_{current_count}.jpg
        filename = f"NDC_{ndc}_NDV_{ndv}_NC_{current_count}.jpg"
        file_path = os.path.join(self.save_dir, filename)
        
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')

        try:
            # encode and write
            _, buffer = cv2.imencode('.jpg', self.latest_frame, [cv2.IMWRITE_JPEG_QUALITY, 90])
            with open(file_path, 'wb') as f:
                f.write(buffer.tobytes())

            entry = {
                "filename": filename,
                "path": file_path,
                "ndv": ndv,
                "ndc": ndc,
                "timestamp": timestamp
            }
            self.captured_frames.append(entry)

            # update flight capture counters
            try:
                self.flight_captures[flight_key] = current_count
                self.save_flight_captures()
                print(f"DEBUG: Captura guardada - {filename} (count={current_count} para {flight_key})")
            except Exception as e:
                print(f"DEBUG: Error actualizando flight_captures: {e}")

            return (len(self.captured_frames), timestamp, filename)
        except Exception as e:
            print(f"Error guardando captura: {e}")
            return (len(self.captured_frames), timestamp, "")

    def process_captured_frames(self):
        """Process/save captured frames and return a results list. For now returns simple placeholders."""
        results = []
        if not self.captured_frames:
            return results

        # Move captured files to carpeta_frames/after/<flight_key>/ and create a simple result
        project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        after_root = os.path.join(project_root, 'carpeta_frames', 'after')
        os.makedirs(after_root, exist_ok=True)

        for entry in list(self.captured_frames):
            ndv = entry.get('ndv', '')
            ndc = entry.get('ndc', '')
            flight_key = f"NDC_{ndc}_NDV_{ndv}" if ndc or ndv else f"{ndc}_{ndv}"
            dest_dir = os.path.join(after_root, flight_key)
            os.makedirs(dest_dir, exist_ok=True)

            src = entry.get('path')
            if src and os.path.exists(src):
                try:
                    dest = os.path.join(dest_dir, entry['filename'])
                    shutil.copy2(src, dest)
                except Exception as e:
                    print(f"Error moviendo archivo {src} -> {dest}: {e}")
            # Prepare a minimal result structure (placeholder)
            results.append({
                'filename': entry.get('filename'),
                'prediction': None,
                'confidence': None
            })

        # Clear captured frames after processing
        count = len(self.captured_frames)
        self.captured_frames.clear()
        return results

    def clear_captured_frames(self):
        count = len(self.captured_frames)
        self.captured_frames.clear()
        return count

# --- EJECUCIÓN PRINCIPAL ---
if __name__ == "__main__":
    capturer = VideoCapture(device_index=1)

    if capturer.start_capture():  # Espera automáticamente a que la cámara esté lista
        try:
            while True:
                time.sleep(2)
                print(f"Estado: {capturer.get_status()}")
        except KeyboardInterrupt:
            print("\n🛑 Interrupción detectada...")
            print("✅ Cámara seguirá corriendo en background. Podés cerrar la terminal.")
    else:
        print("❌ No se pudo iniciar la captura (la cámara no respondió).")
