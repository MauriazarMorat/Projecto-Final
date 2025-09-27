import cv2
import os
import time
import threading
import json
from collections import deque
from datetime import datetime

class VideoCapture:
    def __init__(self, video_path, buffer_size=30):
        self.video_path = os.path.join(os.path.dirname(__file__), "VideoTest.mp4")
        self.buffer_size = buffer_size
        
        # Buffer para frames
        self.frame_buffer = deque(maxlen=buffer_size)
        self.latest_frame = None
        self.captured_frames = []
        
        # Control de threads
        self.is_running = False
        self.capture_thread = None
        
        # Información del video
        self.fps = 30
        self.frame_delay = 1.0 / 30

        # Calcular rutas
        current_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(current_dir)
        self.save_dir = os.path.join(project_root, "carpeta_frames")
        os.makedirs(self.save_dir, exist_ok=True)

        # NUEVO: Archivo JSON para persistencia
        self.json_file = os.path.join(project_root, "flight_captures.json")
        self.flight_captures = self.load_flight_captures()

    def load_flight_captures(self):
        """Carga el diccionario de capturas desde el archivo JSON"""
        try:
            if os.path.exists(self.json_file):
                with open(self.json_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    print(f"Capturas cargadas desde {self.json_file}: {data}")
                    return data
            else:
                print(f"Archivo {self.json_file} no existe, creando nuevo diccionario")
                return {}
        except (json.JSONDecodeError, IOError) as e:
            print(f"Error al cargar {self.json_file}: {e}. Creando nuevo diccionario")
            return {}

    def save_flight_captures(self):
        """Guarda el diccionario de capturas en el archivo JSON"""
        try:
            # Crear directorio si no existe
            os.makedirs(os.path.dirname(self.json_file), exist_ok=True)
            
            with open(self.json_file, 'w', encoding='utf-8') as f:
                json.dump(self.flight_captures, f, ensure_ascii=False, indent=2)
            print(f"Capturas guardadas en {self.json_file}: {self.flight_captures}")
        except IOError as e:
            print(f"Error al guardar {self.json_file}: {e}")

    def start_capture(self):
        """Inicia la captura de video en un hilo separado"""
        if not self.is_running:
            self.is_running = True
            self.capture_thread = threading.Thread(target=self._capture_loop, daemon=True)
            self.capture_thread.start()
            print(f"Captura iniciada: {self.video_path}")
        
    def stop_capture(self):
        """Detiene la captura de video"""
        self.is_running = False
        if self.capture_thread:
            self.capture_thread.join()
        print("Captura detenida")
    
    def _capture_loop(self):
        """Loop principal de captura (ejecuta en hilo separado)"""
        cap = cv2.VideoCapture(self.video_path)
        
        if not cap.isOpened():
            print(f"Error: No se pudo abrir el video {self.video_path}")
            self.is_running = False
            return
        
        self.fps = cap.get(cv2.CAP_PROP_FPS)
        self.frame_delay = 1.0 / self.fps if self.fps > 0 else 1.0 / 30
        
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        print(f"Video cargado - FPS: {self.fps}, Total frames: {total_frames}")
        
        while self.is_running:
            ret, frame = cap.read()
            
            if not ret:
                print("Video terminado, reiniciando...")
                cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
                continue
            
            height, width = frame.shape[:2]
            if width > 1280:
                scale = 1280 / width
                new_width = int(width * scale)
                new_height = int(height * scale)
                frame = cv2.resize(frame, (new_width, new_height))
            
            self.latest_frame = frame.copy()
            self.frame_buffer.append(frame)
            time.sleep(self.frame_delay)
        
        cap.release()
        print("Captura finalizada")
    
    def get_latest_frame(self):
        """Obtiene el frame más reciente"""
        return self.latest_frame
    
    def capture_current_frame(self, NDV, NDC):
        """Captura el frame actual y lo guarda solo en memoria"""
        print(f"DEBUG: latest_frame is None? {self.latest_frame is None}")
        if self.latest_frame is not None:

            flight_key = f"{NDC}_{NDV}"

            # Inicializar en el diccionario si no existe
            if flight_key not in self.flight_captures:
                self.flight_captures[flight_key] = 0
                self.save_flight_captures()  # Guardar inmediatamente

            # Calcular el siguiente número de captura
            next_capture_num = self.flight_captures[flight_key] + len([
                f for f in self.captured_frames 
                if f.get("NDC") == NDC and f.get("NDV") == NDV
            ]) + 1

            print(f"DEBUG: Frame shape: {self.latest_frame.shape}")
            print(f"DEBUG: Vuelo {flight_key} - Guardadas: {self.flight_captures[flight_key]}, Pendientes: {len([f for f in self.captured_frames if f.get('NDC') == NDC and f.get('NDV') == NDV])}, Siguiente: {next_capture_num}")
            
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
            filename = f"NDC_{NDC}_NDV_{NDV}_NC_{next_capture_num:03d}.jpg"

            frame_data = {
                "frame": self.latest_frame.copy(),
                "timestamp": timestamp,
                "NDC": NDC,
                "NDV": NDV,
                "filename": filename,
                "capture_number": next_capture_num
            }

            self.captured_frames.append(frame_data)
            print(f"Frame capturado: {filename}")
            print(f"DEBUG: Total frames capturados en memoria: {len(self.captured_frames)}")
            return len(self.captured_frames), timestamp, filename

        print("DEBUG: No hay frame disponible para capturar")
        return 0, None, None
    
    def get_captured_frames(self):
        return self.captured_frames
    
    def clear_captured_frames(self):
        count = len(self.captured_frames)
        self.captured_frames.clear()
        print(f"Limpiados {count} frames capturados de memoria")
        return count
    
    def process_captured_frames(self):
        """Guarda todos los frames capturados en disco y actualiza el JSON"""
        print(f"DEBUG: Iniciando process_captured_frames, frames disponibles: {len(self.captured_frames)}")
    
        if not self.captured_frames:
            print("DEBUG: NO HAY FRAMES")
            return []

        results = []
        flight_updates = {}
        
        # Procesar cada frame
        for frame_data in self.captured_frames:
            filepath = os.path.join(self.save_dir, frame_data["filename"])
            cv2.imwrite(filepath, frame_data["frame"])
            print(f"DEBUG: Archivo guardado: {filepath}")

            # Contar actualizaciones por vuelo
            flight_key = f"{frame_data['NDC']}_{frame_data['NDV']}"
            if flight_key not in flight_updates:
                flight_updates[flight_key] = 0
            flight_updates[flight_key] += 1

            result = {
                "filename": frame_data["filename"],
                "timestamp": frame_data["timestamp"],
                "NDC": frame_data["NDC"],
                "NDV": frame_data["NDV"],
                "capture_number": frame_data["capture_number"]
            }
            results.append(result)

        # Actualizar contadores persistentes
        for flight_key, count in flight_updates.items():
            if flight_key not in self.flight_captures:
                self.flight_captures[flight_key] = 0
            self.flight_captures[flight_key] += count
            print(f"DEBUG: Vuelo {flight_key} actualizado a {self.flight_captures[flight_key]} capturas")

        # Guardar en JSON
        self.save_flight_captures()

        # Limpiar memoria
        processed_count = len(self.captured_frames)
        self.captured_frames.clear()
        print(f"Procesados y guardados {processed_count} frames")
    
        return results
    
    def get_status(self):
        return {
            "is_running": self.is_running,
            "fps": self.fps,
            "buffer_size": len(self.frame_buffer),
            "captured_count": len(self.captured_frames),
            "has_frame": self.latest_frame is not None,
            "video_path": self.video_path,
            "flight_captures": dict(self.flight_captures)  # Incluir info de capturas por vuelo
        }

    def get_flight_stats(self):
        """Obtiene estadísticas de capturas por vuelo"""
        return dict(self.flight_captures)

    def reset_flight_captures(self):
        """Resetea todas las capturas (útil para testing)"""
        self.flight_captures.clear()
        try:
            if os.path.exists(self.json_file):
                os.remove(self.json_file)
            print("Historial de capturas reseteado")
        except OSError as e:
            print(f"Error al eliminar {self.json_file}: {e}")

if __name__ == "__main__":
    video_path = os.path.join(os.path.dirname(__file__), "VideoTest.mp4")
    capturer = VideoCapture(video_path)
    capturer.start_capture()

    try:
        while True:
            time.sleep(1)
            status = capturer.get_status()
            print(f"Estado: {status}")
    except KeyboardInterrupt:
        capturer.stop_capture()