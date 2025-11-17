import cv2
import os
import time
import threading
import json
from collections import deque
from datetime import datetime
import shutil
import uuid
import numpy as np

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
            if time.time() - start_time > 5:  # Reduced timeout for faster fallback
                print("❌ No se pudo abrir la cámara (timeout).")
                print("⚠️ Usando generador de frames de prueba (modo sin cámara)...")
                cap.release()
                self._start_dummy_capture()
                return True
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
            print("⚠️ Usando generador de frames de prueba (modo sin cámara)...")
            cap.release()
            self._start_dummy_capture()
            return True

        # Cámara lista → cerrar prueba y empezar el hilo
        cap.release()
        print("🚀 Cámara lista, iniciando captura en hilo separado...")
        self.is_running = True
        self.capture_thread = threading.Thread(target=self._capture_loop, daemon=True)
        self.capture_thread.start()
        return True

    def _start_dummy_capture(self):
        """Start dummy frame generator for headless/no-camera mode"""
        print("🚀 Generador de frames iniciado (modo de prueba)...")
        self.is_running = True
        self.capture_thread = threading.Thread(target=self._dummy_capture_loop, daemon=True)
        self.capture_thread.start()

    def _dummy_capture_loop(self):
        """Generate dummy test frames with patterns and timestamp"""
        self.fps = 30
        self.frame_delay = 1.0 / self.fps
        frame_count = 0

        print(f"✅ Generador de frames corriendo - FPS: {self.fps}")

        while self.is_running:
            try:
                # Create a test frame with color gradient and timestamp
                frame = np.zeros((480, 640, 3), dtype=np.uint8)
                
                # Create color gradient background
                for i in range(480):
                    frame[i, :] = [
                        int(255 * i / 480),           # Red gradient
                        int(128),                     # Green constant
                        int(255 * (1 - i / 480))     # Blue inverse gradient
                    ]
                
                # Add timestamp text
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                cv2.putText(
                    frame,
                    f"TEST FRAME - {timestamp}",
                    (20, 100),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    1.2,
                    (255, 255, 255),
                    2
                )
                
                # Add frame counter
                frame_count += 1
                cv2.putText(
                    frame,
                    f"Frame #{frame_count}",
                    (20, 150),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    1,
                    (255, 255, 255),
                    2
                )
                
                # Add "NO CAMERA" watermark
                cv2.putText(
                    frame,
                    "SIN CAMARA - TEST MODE",
                    (20, 450),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    1,
                    (0, 0, 255),
                    2
                )
                
                self.latest_frame = frame.copy()
                self.frame_buffer.append(frame)
                time.sleep(self.frame_delay)
            except Exception as e:
                print(f"Error en generador de frames: {e}")
                time.sleep(0.1)

        print("📸 Generador de frames detenido")

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
        """
        Return metadata for captured frames without moving them to 'after'.
        Captured images are already saved in `carpeta_frames/before/` by `capture_current_frame`.
        This function returns a list of metadata entries and clears the in-memory captured_frames list.
        """
        results = []
        if not self.captured_frames:
            return results

        for entry in list(self.captured_frames):
            results.append({
                'filename': entry.get('filename'),
                'path': entry.get('path'),
                'ndc': entry.get('ndc'),
                'ndv': entry.get('ndv'),
                'timestamp': entry.get('timestamp')
            })

        # Clear captured frames after returning metadata
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
